require "rails/railtie"

module DataMigration
  class Railtie < Rails::Railtie
    rake_tasks do
      load File.expand_path("tasks/data_migration.rake", __dir__)
    end
  end
end
