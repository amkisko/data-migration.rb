module DataMigration
  class Config
    def schema_migrations_path
      @schema_migrations_path ||= "db/migrate"
    end

    attr_writer :data_migrations_path
    def data_migrations_path
      @data_migrations_path ||= "db/data_migrations"
    end

    attr_writer :data_migrations_full_path
    def data_migrations_full_path
      @data_migrations_full_path ||= Rails.root.join(data_migrations_path)
    end

    def data_migrations_path_glob
      "#{data_migrations_full_path}/*.rb"
    end

    attr_writer :generate_spec
    def generate_spec?
      @generate_spec.nil? ? true : @generate_spec
    end

    attr_writer :job_class
    def job_class
      @job_class ||= DataMigration::Job
    end

    attr_writer :task_class
    def task_class
      @task_class ||= DataMigration::Task
    end

    attr_writer :operator_resolver
    def operator_resolver(&block)
      if block_given?
        @operator_resolver = block
      else
        @operator_resolver ||= -> do
          if Object.const_defined?(:ActionReporter)
            ActionReporter.current_user
          elsif Object.const_defined?(:Audited)
            Audited.store[:audited_user]
          end
        end
      end
    end

    attr_writer :monitoring_context
    def monitoring_context(&block)
      if block_given?
        @monitoring_context = block
      else
        @monitoring_context ||= ->(migration) do
          context = {
            data_migration_name: migration.name,
            data_migration_id: migration.try(:to_global_id) || migration.id,
            data_migration_operator_id: migration.operator&.try(:to_global_id) || migration.operator&.id
          }
          if Object.const_defined?(:ActionReporter)
            ActionReporter.current_user ||= migration.operator
            ActionReporter.context(**context)
          elsif Object.const_defined?(:Audited)
            Audited.store[:audited_user] ||= migration.operator
          else
            Rails.logger.info("Data migration context: #{context.inspect}")
          end
        end
      end
    end

    attr_writer :job_queue_name
    def job_queue_name
      @job_queue_name ||= :default
    end

    attr_writer :default_jobs_limit
    def default_jobs_limit
      @default_jobs_limit ||= 10
    end
  end
end
