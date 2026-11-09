require "data_migration/config"
require "data_migration/job"
require "data_migration/task"
require "data_migration/selector"
require "data_migration/cli"
require "data_migration/railtie" if defined?(Rails::Railtie)

module DataMigration
  VERSION = "2.1.0".freeze

  module_function

  def config
    @@config ||= DataMigration::Config.new
  end

  def configure
    yield(config)
  end

  def notify(message, context: {})
    if Object.const_defined?(:ActionReporter)
      ActionReporter.notify(message, context: context.presence || {})
    elsif Object.const_defined?(:Rails)
      Rails.logger.info("#{message} #{context.inspect}")
    end
  end

  def perform_now(...)
    DataMigration::Task.perform_now(...)
  end

  def perform_later(...)
    DataMigration::Task.perform_later(...)
  end

  def prepare(...)
    DataMigration::Task.prepare(...)
  end
end
