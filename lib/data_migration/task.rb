require "active_record"

module DataMigration
  class JobConcurrencyLimitError < StandardError; end
  class JobConflictError < StandardError; end

  def self.tasks_table_name
    "data_migration_tasks"
  end

  class Task < ActiveRecord::Base
    self.table_name = DataMigration.tasks_table_name

    belongs_to :operator, polymorphic: true, optional: true

    before_validation do
      self.operator ||= DataMigration.config.operator_resolver.call
      self.jobs_limit ||= DataMigration.config.default_jobs_limit
    end

    enum :status, {
      started: "started",
      performing: "performing",
      paused: "paused",
      completed: "completed"
    }

    validates :name, presence: true
    validates :pause_minutes, numericality: { greater_than_or_equal_to: 0, only_integer: true }, if: -> { pause_minutes.present? }
    validates :jobs_limit, numericality: { greater_than_or_equal_to: 0, only_integer: true }, if: -> { jobs_limit.present? }
    validate :file_should_exist

    after_save do
      if saved_change_to_started_at? && started_at.present?
        DataMigration.notify("#{user_title} started")
      end
      if saved_change_to_completed_at? && completed_at.present?
        DataMigration.notify("#{user_title} finished")
      end
    end

    scope :not_started, -> { where(status: nil, started_at: nil) }
    scope :started, -> { where(status: :started) }
    scope :paused, -> { where(status: :paused) }
    scope :performing, -> { where(status: :performing) }
    scope :completed, -> { where(status: :completed) }

    def self.job_class
      DataMigration.config.job_class
    end

    def self.perform_now(name, **kwargs)
      create!(name:).perform_now(**kwargs)
    end

    def perform_now(**perform_args)
      update!(kwargs: perform_args)
      self.class.job_class.perform_now(id, **perform_args)
    end

    def self.perform_later(name, **kwargs)
      create!(name:).perform_later(**kwargs)
    end

    def perform_later(**perform_args)
      update!(kwargs: perform_args)
      self.class.job_class.perform_later(id, **perform_args)
    end

    def self.prepare(name, pause_minutes: nil, jobs_limit: nil)
      create!(name:, pause_minutes:, jobs_limit:)
    end

    def self.root_path
      DataMigration.config.data_migrations_full_path
    end

    def self.list
      Dir[DataMigration.config.data_migrations_path_glob].map { |f| File.basename(f, ".*") }
    end

    def file_path
      "#{self.class.root_path}/#{name}.rb"
    end

    def file_exists?
      self.class.list.include?(name)
    end

    def not_started?
      status.nil? && started_at.nil?
    end

    def job_check_in!(job_id, job_args: [], job_kwargs: {})
      self.current_jobs ||= {}

      raise DataMigration::JobConflictError, "#{user_title} already has job ##{job_id}" if current_jobs.key?(job_id)
      raise DataMigration::JobConcurrencyLimitError, "#{user_title} reached limit of #{jobs_limit} jobs" if jobs_limit.present? && current_jobs.size >= jobs_limit

      self.current_jobs[job_id] = {
        ts: Time.current,
        args: job_args,
        kwargs: job_kwargs
      }
      save!
    end

    def job_check_out!(job_id)
      self.current_jobs.delete(job_id)
      save!
    end

    def user_title
      "Data migration ##{id} #{name}"
    end

    def requires_pause?
      pause_minutes.positive? && !paused?
    end

    private

    def file_should_exist
      errors.add(:name, "is not found") unless file_exists?
    end
  end
end
