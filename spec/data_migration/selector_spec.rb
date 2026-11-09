require "spec_helper"

describe DataMigration::Selector do
  let(:data_migrations_full_path) { File.expand_path("../fixtures/data_migrations", __dir__) }

  before do
    allow(DataMigration.config).to receive(:data_migrations_full_path).and_return(data_migrations_full_path)
  end

  describe ".resolve" do
    it "resolves a timestamp VERSION to the migration file stem" do
      expect(described_class.resolve(version: "20241206200111")).to eq("20241206200111_create_users")
    end

    it "resolves a full VERSION stem" do
      expect(described_class.resolve(version: "20241206200111_create_users")).to eq("20241206200111_create_users")
    end

    it "resolves NAME by suffix" do
      expect(described_class.resolve(name: "create_users")).to eq("20241206200111_create_users")
    end

    it "resolves VERSION and NAME together" do
      expect(described_class.resolve(version: "20241206200111", name: "create_users")).to eq(
        "20241206200111_create_users"
      )
    end

    it "raises when nothing matches" do
      expect {
        described_class.resolve(version: "19990101000000")
      }.to raise_error(DataMigration::Selector::NotFound)
    end

    it "raises when VERSION and NAME are both blank" do
      expect {
        described_class.resolve
      }.to raise_error(DataMigration::Selector::NotFound)
    end
  end

  describe ".status_lines" do
    it "lists migrations with latest task status" do
      DataMigration::Task.create!(name: "20241206200111_create_users", status: :completed)

      lines = described_class.status_lines

      expect(lines).to include("20241206200111_create_users\tcompleted")
      expect(lines.grep(/create_bad_users/).first).to end_with("\tnot started")
    end
  end
end
