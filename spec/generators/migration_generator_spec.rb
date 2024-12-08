require "spec_helper"

require "generators/data_migration_generator"

describe DataMigrationGenerator, type: :generator do
  include FileUtils

  subject(:generator) { described_class.start params }

  let(:root_path) { rails_root(File.expand_path("../../../tmp/rspec", __FILE__)) }

  let(:migration_name) { "create_users" }
  let(:params) { [migration_name] }
  let(:created_files) { Dir["#{root_path}/db/data_migrations/*_#{migration_name}.rb"] }
  let(:migration_content) { File.readlines(created_files.first).reject(&:blank?).map(&:strip) }

  before do
    mkdir_p root_path.to_s
    allow(DataMigration.config).to receive(:data_migrations_path).and_return("#{root_path}/db/data_migrations")
    allow(Rails).to receive(:root).and_return(root_path)
  end

  after do
    rm_rf root_path.to_s
  end

  it "creates a migration file" do
    generator

    expect(created_files).not_to be_empty

    expect(migration_content).to include("class CreateUsers")
    expect(migration_content).to include("def perform(**kwargs)")
    expect(migration_content).to include("RSpec.describe CreateUsers, type: :data_migration do")
  end

  context "when generate_spec is false" do
    before do
      DataMigration.config.generate_spec = false
    end

    it "does not add RSpec describe block" do
      generator

      expect(created_files).not_to be_empty

      expect(migration_content).not_to include("RSpec.describe CreateUsers, type: :data_migration do")
    end
  end
end
