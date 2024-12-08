require "spec_helper"

describe DataMigration::Job do
  subject(:job) { DataMigration::Job.new }

  let(:operator) { User.create!(email: "test@example.com") }
  let(:task) { DataMigration::Task.create!(name: migration_name, operator: operator) }

  let(:migration_name) { "20241206200111_create_users" }
  let(:data_migrations_full_path) { File.expand_path("../fixtures/data_migrations", __dir__) }

  before do
    allow(Rails).to receive(:env).and_return(rails_env)
    allow(Rails).to receive(:logger).and_return(rails_logger)
    allow(DataMigration.config).to receive(:data_migrations_full_path).and_return(data_migrations_full_path)
  end

  it "runs rspec spec/fixtures/data_migrations/20241206200111_create_users.rb" do
    output = `RUN_MIGRATION_TESTS=1 rspec #{data_migrations_full_path}/#{migration_name}.rb`
    expect(output).to include("1 example, 0 failures")
  end

  describe "#perform" do
    subject(:perform) { job.perform(task.id, **job_kwargs) }

    let(:job_kwargs) { {} }

    it "updates the task status to completed" do
      expect { perform }.to change { task.reload.status }.to("completed")
    end

    context "when migration file is not found" do
      before do
        task
        allow_any_instance_of(DataMigration::Task).to receive(:file_exists?).and_return(false)
      end

      it "updates the task status to failed" do
        expect(DataMigration).to receive(:notify).with("#{migration_name} not found")
        expect { perform }.not_to raise_error
      end
    end

    context "when migration class is not found" do
      let(:migration_name) { "20241206200112_create_bad_users" }

      it "raises an error" do
        expect { perform }.to raise_error("Data migration class #{migration_name.gsub(/^[0-9_]+/, "").camelize} not found")
      end
    end

    context "when migration class does not implement perform method" do
      let(:migration_name) { "20241206200113_change_users" }

      it "raises an error" do
        expect { perform }.to raise_error("Data migration class #{migration_name.gsub(/^[0-9_]+/, "").camelize} must implement `perform` method")
      end
    end

    context "when there is an enqueue call" do
      let(:migration_name) { "20241206200114_create_batch_users" }

      it "runs the migration in foreground" do
        expect { perform }.to change { User.count }.by(3)
        expect(task.reload.current_jobs.count).to eq(0)
        expect(task.status).to eq("completed")
        expect(User.pluck(:email)).to match_array(["test@example.com", "test_1@example.com", "test_2@example.com"])
      end

      context "when background is true" do
        let(:job_kwargs) { { background: true } }

        before do
          operator
        end

        it "runs the migration in background" do
          expect { perform }.to change(User, :count).by(1)
          expect(task.reload.status).to eq("performing")
          expect(task.current_jobs.count).to eq(0)
          expect(task.kwargs).to eq({})

          expect { job.perform(task.id, index: 2, background: true) }.to change(User, :count).by(1)
          expect(task.reload.status).to eq("performing")
          expect(task.reload.current_jobs.count).to eq(0)
          expect(task.kwargs).to eq({})

          expect { job.perform(task.id, index: 3, background: true) }.to change(User, :count).by(0)
          expect(task.reload.status).to eq("completed")
          expect(task.reload.current_jobs.count).to eq(0)
          expect(task.kwargs).to eq({})
        end
      end
    end
  end
end
