require "spec_helper"

describe DataMigration::Task do
  subject(:task) { DataMigration::Task.create!(name: migration_name) }

  let(:migration_name) { "20241206200111_create_users" }
  let(:data_migrations_full_path) { File.expand_path("../fixtures/data_migrations", __dir__) }

  before do
    # allow(Rails).to receive(:root).and_return(rails_root)
    # allow(Rails).to receive(:logger).and_return(rails_logger)
    allow(DataMigration.config).to receive(:data_migrations_full_path).and_return(data_migrations_full_path)
  end

  describe "#file_path" do
    it "returns the full path to the migration file" do
      expect(task.file_path).to eq("#{data_migrations_full_path}/#{migration_name}.rb")
    end
  end

  describe "#file_exists?" do
    it "returns true if the file exists" do
      expect(task.file_exists?).to be(true)
      expect(task.valid?).to be(true)
    end

    context "when the file does not exist" do
      let(:migration_name) { "20241206200111_create_something_else" }
      let(:task) { DataMigration::Task.new(name: migration_name) }

      it "returns false" do
        expect(task.file_exists?).to be(false)
        expect(task.valid?).to be(false)
      end
    end
  end

  describe "#requires_pause?" do
    before do
      task.status = :started
      task.pause_minutes = 10
    end

    it "returns true if pause_minutes is positive and status is not paused" do
      expect(task.requires_pause?).to be(true)
    end

    context "when pause_minutes is 0" do
      before do
        task.pause_minutes = 0
      end

      it "returns false" do
        expect(task.requires_pause?).to be(false)
      end
    end

    context "when status is paused" do
      before do
        task.status = :paused
      end

      it "returns false" do
        expect(task.requires_pause?).to be(false)
      end
    end
  end

  describe "#perform_now" do
    it "calls the job class with the task and arguments" do
      kwargs = { foo: "bar" }
      expect(DataMigration::Job).to receive(:perform_now).with(task.id, **kwargs)
      task.perform_now(**kwargs)
    end
  end

  describe "#perform_later" do
    it "calls the job class with the task and arguments" do
      kwargs = { foo: "bar" }
      expect(DataMigration::Job).to receive(:perform_later).with(task.id, **kwargs)
      task.perform_later(**kwargs)
    end
  end

  describe "#prepare" do
    subject(:task) { DataMigration::Task.prepare(migration_name, pause_minutes: 10, jobs_limit: 5) }

    it "creates a new task with the given name, pause, and jobs_limit" do
      expect { task }.to change(DataMigration::Task, :count).by(1)
      expect(task.name).to eq(migration_name)
      expect(task.status).to be_nil
      expect(task.pause_minutes).to eq(10)
      expect(task.jobs_limit).to eq(5)
    end

    context "when chained with perform_now" do
      it "calls the job class with the task and arguments" do
        perform_args = { "foo" => "bar" }
        expect(DataMigration::Job).to receive(:perform_now).with(task.id, **perform_args)
        task.perform_now(**perform_args)
        expect(task.kwargs).to eq(perform_args)
      end
    end
  end

  describe "#job_check_in!" do
    subject(:job_check_in!) { task.job_check_in!(job_id, job_args: ["foo"], job_kwargs: { bar: "baz" }) }

    let(:job_id) { "123" }

    it "adds the job to the current_jobs hash" do
      expect { job_check_in! }.to change { task.current_jobs.size }.by(1)
    end

    context "when there is a job with the same id" do
      before do
        task.job_check_in!(job_id, job_args: ["foo"], job_kwargs: { bar: "baz" })
      end

      it "raises a JobConflictError" do
        expect { job_check_in! }.to raise_error(DataMigration::JobConflictError)
      end
    end

    context "when default_jobs_limit is 1 and there are jobs" do
      before do
        DataMigration.config.default_jobs_limit = 1
        task.job_check_in!("321", job_args: ["foo"], job_kwargs: { bar: "baz" })
      end

      it "raises a JobConcurrencyLimitError" do
        expect { job_check_in! }.to raise_error(DataMigration::JobConcurrencyLimitError)
      end
    end
  end

  describe "#job_check_out!" do
    subject(:job_check_out!) { task.job_check_out!(job_id) }

    let(:job_id) { "123" }

    before do
      task.save!
      task.job_check_in!(job_id, job_args: ["foo"], job_kwargs: { bar: "baz" })
    end

    it "removes the job from the current_jobs hash" do
      expect { job_check_out! }.to change { task.current_jobs.size }.by(-1)
      expect(task.current_jobs).not_to have_key(job_id)
    end
  end
end
