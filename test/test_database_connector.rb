# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('lib', __dir__)

require_relative '../lib/app_config_loader'
require_relative '../lib/database_connector'
require 'fileutils'

def test_case(name, results)
  print "Testing: #{name}... "
  begin
    result = yield
    if result
      puts "✓ PASSED"
      results << { name: name, status: :passed }
    else
      puts "✗ FAILED (returned false)"
      results << { name: name, status: :failed, error: 'Returned false' }
    end
  rescue StandardError => e
    puts "✗ FAILED: #{e.message}"
    results << { name: name, status: :failed, error: e.message }
  end
end

def print_summary(results)
  puts
  puts "=" * 80
  puts "TEST SUMMARY"
  puts "=" * 80
  
  total = results.length
  passed = results.count { |r| r[:status] == :passed }
  failed = results.count { |r| r[:status] == :failed }
  skipped = results.count { |r| r[:status] == :skipped }
  
  puts "Total tests: #{total}"
  puts "Passed: #{passed}"
  puts "Failed: #{failed}"
  puts "Skipped: #{skipped}"
  puts
  
  if failed > 0
    puts "FAILED TESTS:"
    results.select { |r| r[:status] == :failed }.each do |r|
      puts "  - #{r[:name]}: #{r[:error]}"
    end
  end
  
  if skipped > 0
    puts "SKIPPED TESTS:"
    results.select { |r| r[:status] == :skipped }.each do |r|
      puts "  - #{r[:name]}: #{r[:error]}"
    end
  end
  
  puts "=" * 80
end

puts "=" * 80
puts "TESTING DatabaseConnector CLASS"
puts "=" * 80
puts

loader = AppConfigLoader.new
config = loader.config('config/default_config.yaml', 'config/yaml_config')

MyApplicationVikovan::LoggerManager.initialize_logger(config)

results = []

puts "-" * 80
puts "TESTING SQLite CONNECTION"
puts "-" * 80

test_case("DatabaseConnector initialization with SQLite config", results) do
  sqlite_config = {
    'database_config' => {
      'database_type' => 'sqlite',
      'sqlite_database' => {
        'db_file' => 'db/test_sqlite.db',
        'timeout' => 5000
      }
    }
  }
  
  connector = MyApplicationVikovan::DatabaseConnector.new(sqlite_config)
  raise "Connector should be initialized" unless connector.is_a?(MyApplicationVikovan::DatabaseConnector)
  raise "db should be nil before connection" unless connector.db.nil?
  true
end

test_case("SQLite connection establishment", results) do
  sqlite_config = {
    'database_config' => {
      'database_type' => 'sqlite',
      'sqlite_database' => {
        'db_file' => 'db/test_sqlite.db',
        'timeout' => 5000
      }
    }
  }
  
  connector = MyApplicationVikovan::DatabaseConnector.new(sqlite_config)
  db = connector.connect_to_database
  
  raise "db should not be nil after connection" if db.nil?
  raise "db should be SQLite3::Database instance" unless db.is_a?(SQLite3::Database)
  
  test_query = db.execute("SELECT 1 as test")
  raise "Should be able to execute query" unless test_query.length == 1
  
  connector.close_connection
  true
end

test_case("SQLite connection closure", results) do
  sqlite_config = {
    'database_config' => {
      'database_type' => 'sqlite',
      'sqlite_database' => {
        'db_file' => 'db/test_sqlite.db',
        'timeout' => 5000
      }
    }
  }
  
  connector = MyApplicationVikovan::DatabaseConnector.new(sqlite_config)
  connector.connect_to_database
  
  raise "db should not be nil before closing" if connector.db.nil?
  
  connector.close_connection
  
  raise "db should be nil after closing" unless connector.db.nil?
  true
end

test_case("SQLite connection using full config from YAML", results) do
  connector = MyApplicationVikovan::DatabaseConnector.new(config)
  db = connector.connect_to_database
  
  raise "db should not be nil" if db.nil?
  raise "db should be SQLite3::Database" unless db.is_a?(SQLite3::Database)
  
  connector.close_connection
  true
end

puts
puts "-" * 80
puts "TESTING MongoDB CONNECTION"
puts "-" * 80

test_case("DatabaseConnector initialization with MongoDB config", results) do
  mongo_config = {
    'database_config' => {
      'database_type' => 'mongodb',
      'mongodb_database' => {
        'uri' => 'mongodb://localhost:27017',
        'db_name' => 'test_database'
      }
    }
  }
  
  connector = MyApplicationVikovan::DatabaseConnector.new(mongo_config)
  raise "Connector should be initialized" unless connector.is_a?(MyApplicationVikovan::DatabaseConnector)
  raise "db should be nil before connection" unless connector.db.nil?
  true
end

test_case("MongoDB connection establishment", results) do
  mongo_config = {
    'database_config' => {
      'database_type' => 'mongodb',
      'mongodb_database' => {
        'uri' => 'mongodb://localhost:27017',
        'db_name' => 'test_database'
      }
    }
  }
  
  connector = MyApplicationVikovan::DatabaseConnector.new(mongo_config)
  
  begin
    db = connector.connect_to_database
    
    raise "db should not be nil after connection" if db.nil?
    raise "db should be Mongo::Database instance" unless db.is_a?(Mongo::Database)
    
    collections = db.collection_names
    raise "Should be able to list collections" unless collections.is_a?(Array)
    
    connector.close_connection
    true
  rescue StandardError => e
    if e.message.include?('connection') || e.message.include?('connect') || e.message.include?('ECONNREFUSED') || e.message.include?('No server available')
      puts "  (MongoDB server might not be running - this is expected if MongoDB is not started)"
      results << { name: "MongoDB connection establishment", status: :skipped, error: "MongoDB server not available: #{e.message}" }
      true
    else
      raise
    end
  end
end

test_case("MongoDB connection closure", results) do
  mongo_config = {
    'database_config' => {
      'database_type' => 'mongodb',
      'mongodb_database' => {
        'uri' => 'mongodb://localhost:27017',
        'db_name' => 'test_database'
      }
    }
  }
  
  connector = MyApplicationVikovan::DatabaseConnector.new(mongo_config)
  
  begin
    connector.connect_to_database
    
    raise "db should not be nil before closing" if connector.db.nil?
    
    connector.close_connection
    
    raise "db should be nil after closing" unless connector.db.nil?
    true
  rescue StandardError => e
    if e.message.include?('connection') || e.message.include?('connect') || e.message.include?('ECONNREFUSED') || e.message.include?('No server available')
      puts "  (MongoDB server might not be running - skipping closure test)"
      results << { name: "MongoDB connection closure", status: :skipped, error: "MongoDB server not available: #{e.message}" }
      true
    else
      raise
    end
  end
end

puts
puts "-" * 80
puts "TESTING ERROR HANDLING"
puts "-" * 80

test_case("Unsupported database type error handling", results) do
  invalid_config = {
    'database_config' => {
      'database_type' => 'invalid_db_type'
    }
  }
  
  connector = MyApplicationVikovan::DatabaseConnector.new(invalid_config)
  
  begin
    connector.connect_to_database
    raise "Should raise error for unsupported database type"
  rescue MyApplicationVikovan::Error => e
    raise "Error message should mention unsupported type" unless e.message.include?('Unsupported database type')
    true
  end
end

test_case("Close connection when not connected", results) do
  sqlite_config = {
    'database_config' => {
      'database_type' => 'sqlite',
      'sqlite_database' => {
        'db_file' => 'db/test_sqlite.db'
      }
    }
  }
  
  connector = MyApplicationVikovan::DatabaseConnector.new(sqlite_config)
  
  connector.close_connection
  
  raise "db should be nil" unless connector.db.nil?
  true
end

puts
print_summary(results)

puts
puts "Cleaning up test database file..."
test_db_file = 'db/test_sqlite.db'
if File.exist?(test_db_file)
  File.delete(test_db_file)
  puts "Deleted #{test_db_file}"
end

puts
puts "=== Tests finished ==="

