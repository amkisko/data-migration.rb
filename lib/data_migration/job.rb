require "active_job"

module DataMigration
  class Job < ActiveJob::Base
    queue_as { DataMigration.config.job_queue_name }

    discard_on StandardError

    def perform(task_id, *job_args, **job_kwargs)
      task = DataMigration::Task.find(task_id)
      DataMigration.config.monitoring_context.call(task)

      migration_name = task.name
      migration_path = task.file_path

      unless task.file_exists?
        DataMigration.notify("#{migration_name} not found")
        return
      end

      task.job_check_in!(job_id, job_args:, job_kwargs:)

      require migration_path
      klass_name = migration_name.gsub(/^[0-9_]+/, "").camelize
      klass = klass_name.safe_constantize
      raise "Data migration class #{klass_name} not found" unless klass.is_a?(Class)
      raise "Data migration class #{klass_name} must implement `perform` method" unless klass.method_defined?(:perform)

      if task.started_at.blank?
        task.update!(started_at: Time.current, status: :started)
      end

      if task.requires_pause?
        DataMigration::Job.set(wait: task.pause_minutes.minutes).perform_later(task_id, *job_args, **job_kwargs)
        task.update!(status: :paused)
        return
      end

      Thread.current[:data_migration_enqueue_called] ||= {}
      Thread.current[:data_migration_enqueue_kwargs] ||= {}
      klass.define_method(:enqueue) do |**enqueue_kwargs|
        Thread.current[:data_migration_enqueue_called][klass.name] = true
        Thread.current[:data_migration_enqueue_kwargs][klass.name] = enqueue_kwargs
      end

      task.update!(status: :performing, pause_minutes: 0)
      klass.new.perform(**job_kwargs)
      task.job_check_out!(job_id)

      enqueue_called = Thread.current[:data_migration_enqueue_called].delete(klass.name)
      enqueue_kwargs = Thread.current[:data_migration_enqueue_kwargs].delete(klass.name)
      if enqueue_called
        if enqueue_kwargs[:background] == false
          self.class.new.perform(task_id, *job_args, **enqueue_kwargs)
        else
          DataMigration::Job.perform_later(task_id, *job_args, **enqueue_kwargs)
        end
      else
        task.update!(completed_at: Time.current, status: :completed)
      end
    end
  end
end
