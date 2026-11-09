require "spec_helper"
require "rake"

describe "db:migrate:data" do
  let(:data_migrations_full_path) { File.expand_path("../fixtures/data_migrations", __dir__) }
  let(:task_name) { "db:migrate:data" }

  before do
    allow(DataMigration.config).to receive(:data_migrations_full_path).and_return(data_migrations_full_path)
    Rake::Task.clear
    Rake::Task.define_task(:environment)
    load File.expand_path("../../lib/data_migration/tasks/data_migration.rake", __dir__)
  end

  after do
    ENV.delete("VERSION")
    ENV.delete("NAME")
  end

  it "runs the selected migration through DataMigration.perform_now" do
    ENV["VERSION"] = "20241206200111"
    expect(DataMigration).to receive(:perform_now).with("20241206200111_create_users")

    Rake::Task[task_name].invoke
  end

  it "lists migrations when VERSION and NAME are blank" do
    expect(DataMigration).not_to receive(:perform_now)

    expect { Rake::Task[task_name].invoke }.to output(/Available data migrations:/).to_stdout
  end
end
