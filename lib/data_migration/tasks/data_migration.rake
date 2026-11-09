namespace :db do
  namespace :migrate do
    desc "Run a data migration with VERSION= and/or NAME= (lists migrations when both are blank)"
    task data: :environment do
      version = ENV["VERSION"]
      name = ENV["NAME"]

      if version.to_s.strip.empty? && name.to_s.strip.empty?
        puts "Available data migrations:"
        DataMigration::Selector.status_lines.each { |line| puts line }
        next
      end

      migration_name = DataMigration::Selector.resolve(version: version, name: name)
      DataMigration.perform_now(migration_name)
    end
  end
end
