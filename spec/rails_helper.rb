require "active_record"

require "data_migration"

require "support/rails_helpers"

RSpec.configure do |config|
  include RailsHelpers

  config.before(:suite) do
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
    load File.expand_path("../fixtures/schema.rb", __FILE__)
  end

  config.before(:each) do
    tables = ActiveRecord::Base.connection.tables
    tables.each do |table|
      ActiveRecord::Base.connection.execute("DELETE FROM #{table}")
    end
  end
end
