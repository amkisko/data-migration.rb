namespace :db do
  namespace :migrate do
    desc "Run a data migration with VERSION= and/or NAME= (lists migrations when both are blank)"
    task data: :environment do
      DataMigration::Cli.run!
    end
  end
end
