module DataMigration
  module Cli
    module_function

    def run!(env = ENV)
      version = env["VERSION"]
      name = env["NAME"]

      if version.to_s.strip.empty? && name.to_s.strip.empty?
        puts "Available data migrations:"
        DataMigration::Selector.status_lines.each { |line| puts line }
        return :listed
      end

      migration_name = DataMigration::Selector.resolve(version: version, name: name)
      DataMigration.perform_now(migration_name)
      :ran
    end
  end
end
