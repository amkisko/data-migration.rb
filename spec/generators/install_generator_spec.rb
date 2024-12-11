require "spec_helper"

require "generators/data_migration/install_generator"

describe DataMigration::Generators::InstallGenerator, type: :generator do
  include FileUtils

  subject(:generator) { described_class.start params }

  let(:root_path) { rails_root(File.expand_path("../../../tmp/rspec", __FILE__)) }

  let(:migration_name) { "data_migration_tasks" }
  let(:params) { [migration_name] }
  let(:created_files) { Dir["#{root_path}/db/migrate/*_#{migration_name}.rb"] }
  let(:migration_content) { File.readlines(created_files.first).reject(&:blank?).map(&:strip) }

  before do
    mkdir_p root_path.to_s
    allow(DataMigration.config).to receive(:schema_migrations_path).and_return("#{root_path}/db/migrate")
    allow(Rails).to receive(:root).and_return(root_path)
  end

  after do
    rm_rf root_path.to_s
  end

  it "creates a migration file" do
    generator

    expect(created_files).not_to be_empty

    expect(migration_content).to include("create_table :data_migration_tasks, force: true do |t|")
  end

  context "when tasks_table_name is not default" do
    before do
      allow(DataMigration).to receive(:tasks_table_name).and_return("other_data_migration_tasks")
    end

    it "creates a migration file with the correct table name" do
      generator

      expect(created_files).not_to be_empty

      expect(migration_content).to include("create_table :other_data_migration_tasks, force: true do |t|")
    end
  end
end
