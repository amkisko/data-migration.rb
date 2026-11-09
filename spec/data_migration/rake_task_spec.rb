require "spec_helper"
require "rake"

describe "db:migrate:data" do
  let(:task_name) { "db:migrate:data" }

  before do
    Rake::Task.clear
    Rake::Task.define_task(:environment)
    load File.expand_path("../../lib/data_migration/tasks/data_migration.rake", __dir__)
  end

  it "delegates to DataMigration::Cli.run!" do
    expect(DataMigration::Cli).to receive(:run!).and_return(:listed)

    Rake::Task[task_name].invoke
  end
end
