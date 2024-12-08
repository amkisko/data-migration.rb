require "rails/generators"
require "rails/generators/active_record"
require "rails/generators/active_record/migration/migration_generator"

class InstallGenerator < ActiveRecord::Generators::MigrationGenerator
  source_root File.expand_path("../templates", __FILE__)

  def create_migration_file
    set_local_assigns!
    validate_file_name!
    migration_template "install_#{name}.rb", "#{DataMigration.config.schema_migrations_path}/#{file_name}.rb"
  end

  def migration_parent
    "ActiveRecord::Migration[#{ActiveRecord::Migration.current_version}]"
  end
end
