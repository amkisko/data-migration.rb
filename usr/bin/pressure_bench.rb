#!/usr/bin/env ruby
# frozen_string_literal: true

# Pressure probe for data-migration hot path: Selector.resolve + Job#perform batches.
# Binding: docs/issues/*_pressure-benchmark.md, ceilings: config/pressure_ceilings.yml
#
# Stages (calibrated with distinct sleeps): calibrate_resolve, calibrate_perform, calibrate_checkout
# Memory probe class: process_lifetime
# Network: not_in_scope
# samples-per-load: 3; propose-basis: median * 1.15; min episode iterations: 10

require "bundler/setup"
require "yaml"
require "json"
require "fileutils"
require "tmpdir"

ROOT = File.expand_path("../..", __dir__)
Dir.chdir(ROOT)

require "logger"
require "active_record"
require "active_job"
require "data-migration"

ActiveJob::Base.queue_adapter = :test
ActiveJob::Base.logger = Logger.new(nil)

DB_PATH = File.join(Dir.tmpdir, "data-migration-pressure-#{Process.pid}.sqlite3")
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: DB_PATH)
load File.join(ROOT, "spec/fixtures/schema.rb")

module Rails
  def self.root
    Pathname.new(ROOT)
  end

  def self.env
    ActiveSupport::StringInquirer.new("test")
  end

  def self.logger
    @logger ||= Logger.new(nil)
  end
end

class User < ActiveRecord::Base
  self.table_name = "users"
end

fixtures = File.join(ROOT, "spec/fixtures/data_migrations")
DataMigration.config.data_migrations_full_path = fixtures

CEILINGS_PATH = File.join(ROOT, "config/pressure_ceilings.yml")
SAMPLES = Integer(ENV.fetch("PRESSURE_SAMPLES", "3"))
LOAD = Integer(ENV.fetch("PRESSURE_LOAD", "5"))
MODE = ENV.fetch("PRESSURE_MODE", "measure") # calibrate|measure|gate

def rss_bytes
  if File.readable?("/proc/self/status")
    File.readlines("/proc/self/status").each do |line|
      return Integer(Regexp.last_match(1)) * 1024 if line =~ /^VmRSS:\s+(\d+)/
    end
  end
  out = `ps -o rss= -p #{Process.pid} 2>/dev/null`.to_s.strip
  return Integer(out) * 1024 unless out.empty?

  # Fallback when process table is unavailable: track Ruby object heap bytes.
  ObjectSpace.count_objects[:TOTAL].to_i * 40
rescue
  0
end

def time_stage(name)
  started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  cpu_before = Process.times
  yield
  cpu_after = Process.times
  wall_ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000.0
  cpu_ms = ((cpu_after.utime + cpu_after.stime) - (cpu_before.utime + cpu_before.stime)) * 1000.0
  {stage: name, wall_ms: wall_ms, cpu_ms: cpu_ms, rss_bytes: rss_bytes}
end

def calibrate!
  results = []
  results << time_stage("calibrate_resolve") do
    sleep 0.01
    DataMigration::Selector.resolve(version: "20241206200111")
  end
  results << time_stage("calibrate_perform") do
    sleep 0.02
    task = DataMigration::Task.create!(name: "20241206200111_create_users")
    DataMigration::Job.perform_now(task.id, background: false)
  end
  results << time_stage("calibrate_checkout") do
    sleep 0.03
    DataMigration::Task.list
  end
  walls = results.pluck(:wall_ms)
  raise "calibrate failed: stages not distinct #{walls.inspect}" unless walls.uniq.size == walls.size
  results
end

def measure_load(batch_count)
  samples = []
  SAMPLES.times do
    ActiveRecord::Base.connection.execute("DELETE FROM data_migration_tasks")
    ActiveRecord::Base.connection.execute("DELETE FROM users") if ActiveRecord::Base.connection.table_exists?("users")
    sample = {resolve_p95_us: nil, perform_wall_ms: nil, cpu_ms: nil, rss_bytes: nil, storage_bytes: 0}
    resolve_times = []
    batch_count.times do
      t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      DataMigration::Selector.resolve(version: "20241206200111")
      resolve_times << (Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0) * 1_000_000
    end
    sample[:resolve_p95_us] = resolve_times.sort[Integer((resolve_times.size - 1) * 0.95)]

    cpu_before = Process.times
    wall_started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    task = DataMigration::Task.create!(name: "20241206200114_create_batch_users")
    DataMigration::Job.perform_now(task.id, background: false, index: 1)
    wall = Process.clock_gettime(Process::CLOCK_MONOTONIC) - wall_started
    cpu_after = Process.times
    sample[:perform_wall_ms] = wall * 1000.0
    sample[:cpu_ms] = ((cpu_after.utime + cpu_after.stime) - (cpu_before.utime + cpu_before.stime)) * 1000.0
    sample[:rss_bytes] = rss_bytes
    sample[:storage_bytes] = File.size(DB_PATH)
    samples << sample
  end
  samples
end

def median(values)
  sorted = values.sort
  sorted[sorted.size / 2]
end

def summarize(samples)
  {
    resolve_p95_us: median(samples.pluck(:resolve_p95_us)),
    resolve_p95_us_max: samples.pluck(:resolve_p95_us).max,
    perform_wall_ms: median(samples.pluck(:perform_wall_ms)),
    perform_wall_ms_max: samples.pluck(:perform_wall_ms).max,
    cpu_ms: median(samples.pluck(:cpu_ms)),
    rss_bytes: median(samples.pluck(:rss_bytes)),
    storage_bytes: median(samples.pluck(:storage_bytes)),
    network: "not_in_scope"
  }
end

# Timing series use max * headroom (host noise); resource series use median * headroom.
def propose(summary, timing_headroom: 1.5, resource_headroom: 1.15)
  {
    "resolve_p95_us" => (summary[:resolve_p95_us_max] * timing_headroom).ceil,
    "perform_wall_ms" => (summary[:perform_wall_ms_max] * timing_headroom).ceil,
    "cpu_ms" => (summary[:cpu_ms] * resource_headroom).ceil,
    "rss_bytes" => (summary[:rss_bytes] * resource_headroom).ceil,
    "storage_bytes" => (summary[:storage_bytes] * resource_headroom).ceil,
    "network" => "not_in_scope"
  }
end

def gate!(summary, ceilings)
  failures = []
  %i[resolve_p95_us perform_wall_ms cpu_ms rss_bytes storage_bytes].each do |key|
    next unless ceilings[key.to_s]
    failures << "#{key}=#{summary[key]} > #{ceilings[key.to_s]}" if summary[key] > ceilings[key.to_s]
  end
  raise "gate failed: #{failures.join(", ")}" unless failures.empty?
end

begin
  case MODE
  when "calibrate"
    puts JSON.pretty_generate(calibrate: calibrate!)
  when "measure"
    calibrate!
    summary = summarize(measure_load(LOAD))
    proposed = propose(summary)
    puts JSON.pretty_generate(load: LOAD, samples: SAMPLES, summary: summary, proposed_ceilings: proposed)
  when "gate"
    calibrate!
    ceilings = YAML.load_file(CEILINGS_PATH)
    summary = summarize(measure_load(LOAD))
    gate!(summary, ceilings)
    puts JSON.pretty_generate(load: LOAD, summary: summary, gate: "pass")
  when "write"
    calibrate!
    summary = summarize(measure_load(LOAD))
    proposed = propose(summary)
    FileUtils.mkdir_p(File.dirname(CEILINGS_PATH))
    File.write(CEILINGS_PATH, YAML.dump(proposed))
    puts JSON.pretty_generate(wrote: CEILINGS_PATH, ceilings: proposed)
  else
    warn "Unknown PRESSURE_MODE=#{MODE}"
    exit 1
  end
ensure
  FileUtils.rm_f(DB_PATH) if defined?(DB_PATH)
end
