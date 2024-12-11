require "rails/generators"
require "rails/generators/active_record"
require "rails/generators/active_record/migration/migration_generator"

module DataMigration
  module Generators
    class InstallGenerator < ActiveRecord::Generators::MigrationGenerator
      source_root File.expand_path("../templates", __FILE__)

      attr_reader :table_exists, :table_columns
      def create_migration_file
        if ActiveRecord::Base.connection.table_exists?(name)
          puts "\e[31mWARNING: Table `#{name}` already exists\e[0m"
          @table_exists = true
          @table_columns = ActiveRecord::Base.connection.columns(name)
        end

        set_local_assigns!
        validate_file_name!
        migration_template "install_#{name}.rb", "#{DataMigration.config.schema_migrations_path}/install_#{file_name}.rb"
      end

      def migration_parent
        "ActiveRecord::Migration[#{ActiveRecord::Migration.current_version}]"
      end
    end
  end
end
