require "spec_helper"

describe DataMigration::Cli do
  let(:data_migrations_full_path) { File.expand_path("../fixtures/data_migrations", __dir__) }

  before do
    allow(DataMigration.config).to receive(:data_migrations_full_path).and_return(data_migrations_full_path)
  end

  describe ".run!" do
    it "lists migrations when VERSION and NAME are blank" do
      expect(DataMigration).not_to receive(:perform_now)

      expect {
        expect(described_class.run!({})).to eq(:listed)
      }.to output(/Available data migrations:/).to_stdout
    end

    it "runs the resolved migration" do
      expect(DataMigration).to receive(:perform_now).with("20241206200111_create_users")

      expect(described_class.run!("VERSION" => "20241206200111")).to eq(:ran)
    end
  end
end
