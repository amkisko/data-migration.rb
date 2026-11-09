module DataMigration
  class Selector
    class Error < StandardError; end
    class NotFound < Error; end
    class Ambiguous < Error; end

    def self.resolve(version: nil, name: nil)
      new(version: version, name: name).resolve
    end

    def self.status_lines
      DataMigration::Task.list.map do |migration_name|
        task = DataMigration::Task.where(name: migration_name).order(id: :desc).first
        status = task&.status || "not started"
        "#{migration_name}\t#{status}"
      end
    end

    def initialize(version: nil, name: nil)
      @version = version.to_s.strip.presence
      @name = name.to_s.strip.presence
    end

    def resolve
      raise NotFound, "VERSION or NAME is required" if @version.nil? && @name.nil?

      available = DataMigration::Task.list
      matches = available.select { |migration_name| match?(migration_name) }
      raise NotFound, "No data migration matches VERSION=#{@version.inspect} NAME=#{@name.inspect}" if matches.empty?
      raise Ambiguous, "Multiple data migrations match: #{matches.join(", ")}" if matches.size > 1

      matches.first
    end

    private

    def match?(migration_name)
      return migration_name == @version || migration_name.start_with?("#{@version}_") if @version && @name.nil?
      return migration_name == @name || migration_name.end_with?("_#{@name}") if @name && @version.nil?

      combined = @version.include?("_") ? @version : "#{@version}_#{@name}"
      migration_name == combined || migration_name == @version
    end
  end
end
