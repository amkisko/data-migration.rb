require "rails/generators"
require "rails/generators/active_record"
require "rails/generators/active_record/migration/migration_generator"

class DataMigrationGenerator < ActiveRecord::Generators::MigrationGenerator
  source_root File.expand_path("../templates", __FILE__)

  def create_migration_file
    set_local_assigns!
    validate_file_name!
    migration_template "data_migration.rb", "#{DataMigration.config.data_migrations_path}/#{file_name}.rb"
  end
end
