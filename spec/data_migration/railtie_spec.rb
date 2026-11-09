require "spec_helper"
require "rake"

describe "DataMigration::Railtie" do
  it "registers the rake task loader" do
    rails = Module.new
    railtie = Class.new do
      def self.rake_tasks(&block)
        @rake_tasks = block
      end

      def self.rake_tasks_block
        @rake_tasks
      end
    end
    rails.const_set(:Railtie, railtie)
    stub_const("Rails", rails)

    load File.expand_path("../../../lib/data_migration/railtie.rb", __FILE__)

    expect(DataMigration::Railtie.ancestors).to include(rails::Railtie)
    block = Array(DataMigration::Railtie.rake_tasks_block).first
    expect(block).to be_a(Proc)

    Rake::Task.clear
    Rake.application = Rake::Application.new
    expect { block.call }.not_to raise_error
    expect(Rake::Task.task_defined?("db:migrate:data")).to be(true)
  end
end
