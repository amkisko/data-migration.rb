require "spec_helper"

describe DataMigration do
  let(:gem_specification) { Gem::Specification.load(File.expand_path("../../data-migration.gemspec", __FILE__)) }

  it "has a version number" do
    expect(described_class::VERSION).to eq gem_specification.version.to_s
  end

  let(:changelog_file) { File.expand_path("../../CHANGELOG.md", __FILE__) }
  it "has changelog for the version" do
    expect(File.exist?(changelog_file)).to be true
    expect(File.read(changelog_file)).to include("# #{gem_specification.version}")
  end

  let(:license_file) { File.expand_path("../../LICENSE.md", __FILE__) }
  it "has license" do
    expect(File.exist?(license_file)).to be true
  end

  let(:readme_file) { File.expand_path("../../README.md", __FILE__) }
  it "has readme" do
    expect(File.exist?(readme_file)).to be true
  end

  describe ".notify" do
    subject(:notify) { DataMigration.notify("test") }
    let(:action_reporter) { Class.new }
    before do
      stub_const("ActionReporter", action_reporter)
    end

    it "sends message to ActionReporter" do
      expect(action_reporter).to receive(:notify).with("test", context: {})
      expect { notify }.not_to raise_error
    end
  end

  describe ".perform_now" do
    subject(:perform_now) { DataMigration.perform_now("test_perform_now") }

    it "delegates to DataMigration::Task.perform_now" do
      expect(DataMigration::Task).to receive(:perform_now).with("test_perform_now")
      expect { perform_now }.not_to raise_error
    end
  end

  describe ".perform_later" do
    subject(:perform_later) { DataMigration.perform_later("test_perform_later") }

    it "delegates to DataMigration::Task.perform_later" do
      expect(DataMigration::Task).to receive(:perform_later).with("test_perform_later")
      expect { perform_later }.not_to raise_error
    end
  end

  describe ".prepare" do
    subject(:prepare) { DataMigration.prepare("test_prepare") }

    it "delegates to DataMigration::Task.prepare" do
      expect(DataMigration::Task).to receive(:prepare).with("test_prepare")
      expect { prepare }.not_to raise_error
    end
  end
end
