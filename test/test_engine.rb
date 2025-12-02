# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('lib', __dir__)

require_relative '../lib/engine'

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
    results <<({ name: name, status: :failed, error: e.message })
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

  puts "Total tests: #{total}"
  puts "Passed: #{passed}"
  puts "Failed: #{failed}"
  puts

  if failed.positive?
    puts "FAILED TESTS:"
    results.select { |r| r[:status] == :failed }.each do |r|
      puts "  - #{r[:name]}: #{r[:error]}"
    end
  end

  puts "=" * 80
end

class EngineForTesting < MyApplicationVikovan::Engine
  attr_reader :called_methods

  def initialize
    super(AppConfigLoader.new)
    @called_methods = []
  end

  private

  def run_website_parser
    @called_methods << :run_website_parser
  end

  def run_save_to_csv
    @called_methods << :run_save_to_csv
  end

  def run_save_to_json
    @called_methods << :run_save_to_json
  end

  def run_save_to_yaml
    @called_methods << :run_save_to_yaml
  end

  def run_save_to_sqlite
    @called_methods << :run_save_to_sqlite
  end

  def run_save_to_mongodb
    @called_methods << :run_save_to_mongodb
  end
end

puts "=" * 80
puts "TESTING Engine CLASS (method dispatch by configuration)"
puts "=" * 80
puts

results = []

test_case("run_methods with all flags = 0 does not call anything", results) do
  engine = EngineForTesting.new
  params = {
    run_website_parser: 0,
    run_save_to_csv: 0,
    run_save_to_json: 0,
    run_save_to_yaml: 0,
    run_save_to_sqlite: 0,
    run_save_to_mongodb: 0
  }

  engine.run_methods(params)

  raise "No methods should be called" unless engine.called_methods.empty?
  true
end

test_case("run_methods calls only run_website_parser when its flag = 1", results) do
  engine = EngineForTesting.new
  params = {
    run_website_parser: 1,
    run_save_to_csv: 0,
    run_save_to_json: 0,
    run_save_to_yaml: 0,
    run_save_to_sqlite: 0,
    run_save_to_mongodb: 0
  }

  engine.run_methods(params)

  expected = [:run_website_parser]
  raise "Expected #{expected}, got #{engine.called_methods.inspect}" unless engine.called_methods == expected
  true
end

test_case("run_methods calls multiple methods according to flags", results) do
  engine = EngineForTesting.new
  params = {
    run_website_parser: 1,
    run_save_to_csv: 1,
    run_save_to_json: 0,
    run_save_to_yaml: 1,
    run_save_to_sqlite: 0,
    run_save_to_mongodb: 1
  }

  engine.run_methods(params)

  called = engine.called_methods
  raise "run_website_parser should be called" unless called.include?(:run_website_parser)
  raise "run_save_to_csv should be called" unless called.include?(:run_save_to_csv)
  raise "run_save_to_yaml should be called" unless called.include?(:run_save_to_yaml)
  raise "run_save_to_mongodb should be called" unless called.include?(:run_save_to_mongodb)

  unexpected = called - [:run_website_parser, :run_save_to_csv, :run_save_to_yaml, :run_save_to_mongodb]
  raise "No unexpected methods should be called, got #{unexpected.inspect}" unless unexpected.empty?

  true
end

test_case("run_methods ignores unknown keys and does not raise", results) do
  engine = EngineForTesting.new
  params = {
    run_website_parser: 1,
    run_save_to_csv: 0,
    run_unknown_method: 1
  }

  engine.run_methods(params)

  raise "Only run_website_parser should be called" unless engine.called_methods == [:run_website_parser]
  true
end

test_case("run_methods treats string keys the same as symbol keys", results) do
  engine = EngineForTesting.new
  params = {
    'run_website_parser' => 0,
    'run_save_to_csv' => 1,
    'run_save_to_json' => '1',
    'run_save_to_yaml' => '0'
  }

  engine.run_methods(params)

  called = engine.called_methods
  raise "run_save_to_csv should be called" unless called.include?(:run_save_to_csv)
  raise "run_save_to_json should be called" unless called.include?(:run_save_to_json)

  unexpected = called - [:run_save_to_csv, :run_save_to_json]
  raise "No unexpected methods should be called, got #{unexpected.inspect}" unless unexpected.empty?

  true
end

puts
print_summary(results)
puts
puts "=== Engine tests finished ==="


