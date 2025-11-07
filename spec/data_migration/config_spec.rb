require "spec_helper"

describe DataMigration::Config do
  subject(:config) { described_class.new }

  let(:current_user) do
    User.new(id: 1)
  end
  let(:action_reporter) do
    Class.new do
      def current_user
        User.new(id: 3)
      end

      def context(**kwargs)
        kwargs
      end
    end.new
  end
  let(:audited) do
    Class.new do
      def store
        { audited_user: User.new(id: 4) }
      end
    end.new
  end
  let(:logger) do
    Class.new do
      def info(message)
        puts message
      end
    end.new
  end
  let(:other_user) do
    User.new(id: 2)
  end
  let(:migration) do
    DataMigration::Task.new(id: 1, name: "test", operator: other_user)
  end

  before do
    allow(Rails).to receive(:root).and_return(rails_root)
    allow(Rails).to receive(:logger).and_return(logger)
  end

  it "has default schema migrations path" do
    expect(config.schema_migrations_path).to eq "db/migrate"
  end

  it "has default data migrations path" do
    expect(config.data_migrations_path).to eq "db/data_migrations"
  end

  it "has default data migrations full path" do
    expect(config.data_migrations_full_path).to eq Rails.root.join("db/data_migrations")
  end

  it "has default data migrations path glob" do
    expect(config.data_migrations_path_glob).to eq Rails.root.join("db/data_migrations/*.rb").to_s
  end

  it "has default generate spec" do
    expect(config.generate_spec?).to be true
  end

  it "has default task class" do
    expect(config.task_class).to eq DataMigration::Task
  end

  it "has default job class" do
    expect(config.job_class).to eq DataMigration::Job
  end

  it "has default job queue name" do
    expect(config.job_queue_name).to eq :default
  end

  it "has default default jobs limit" do
    expect(config.default_jobs_limit).to eq 10
  end

  it "has default monitoring context" do
    expect(config.monitoring_context).to be_a Proc

    expect(Rails.logger).to receive(:info).with(
      match(/Data migration context: \{.*data_migration_name.*"test".*data_migration_id.*1.*data_migration_operator_id.*2.*\}/)
    )
    expect { config.monitoring_context.call(migration) }.not_to raise_error
  end

  context "when ActionReporter is defined" do
    before do
      stub_const("ActionReporter", action_reporter)
    end

    it "sets monitoring context" do
      expect(ActionReporter).to receive(:context).with(
        data_migration_name: "test",
        data_migration_id: 1,
        data_migration_operator_id: 2
      )
      expect(ActionReporter).to receive(:current_user).and_return(nil)
      expect(ActionReporter).to receive(:current_user=).with(other_user)
      expect { config.monitoring_context.call(migration) }.not_to raise_error
    end
  end

  context "when Audited is defined" do
    before do
      stub_const("Audited", audited)
    end

    it "sets monitoring context" do
      expect(Audited).to receive(:store).and_return(audited_user: User.new(id: 5))
      expect { config.monitoring_context.call(migration) }.not_to raise_error
    end
  end
end
