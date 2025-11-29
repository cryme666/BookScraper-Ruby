# frozen_string_literal: true

require_relative '../lib/app_config_loader'
require_relative '../lib/my_application_vikovan'
require 'fileutils'

class TestConfigurator
  def self.run_all_tests
    puts "=" * 80
    puts "COMPREHENSIVE TESTING OF Configurator CLASS"
    puts "=" * 80
    puts

    loader = AppConfigLoader.new
    config = loader.config('config/default_config.yaml', 'config/yaml_config')
    MyApplicationVikovan::LoggerManager.initialize_logger(config)

    test_results = {
      configurator_basic: [],
      configurator_configure: [],
      configurator_available_methods: [],
      configurator_logging: []
    }

    test_results[:configurator_basic] = test_configurator_basic
    test_results[:configurator_configure] = test_configurator_configure
    test_results[:configurator_available_methods] = test_configurator_available_methods
    test_results[:configurator_logging] = test_configurator_logging

    print_summary(test_results)
    test_results
  end

  private

  def self.test_configurator_basic
    puts "-" * 80
    puts "TESTING Configurator CLASS - BASIC FUNCTIONALITY"
    puts "-" * 80
    results = []

    test_case("Configurator initialization", results) do
      configurator = MyApplicationVikovan::Configurator.new
      raise "Configurator should be initialized" unless configurator.is_a?(MyApplicationVikovan::Configurator)
      raise "Config should be a Hash" unless configurator.config.is_a?(Hash)
      true
    end

    test_case("Configurator has default config keys", results) do
      configurator = MyApplicationVikovan::Configurator.new
      expected_keys = [:run_website_parser, :run_save_to_csv, :run_save_to_json, 
                       :run_save_to_yaml, :run_save_to_sqlite, :run_save_to_mongodb]
      raise "Config should have all default keys" unless expected_keys.all? { |key| configurator.config.key?(key) }
      true
    end

    test_case("Configurator default values are zero", results) do
      configurator = MyApplicationVikovan::Configurator.new
      raise "All default values should be 0" unless configurator.config.values.all? { |v| v == 0 }
      true
    end

    test_case("Configurator config attribute is accessible", results) do
      configurator = MyApplicationVikovan::Configurator.new
      configurator.config[:run_save_to_csv] = 1
      raise "Config should be writable" unless configurator.config[:run_save_to_csv] == 1
      true
    end

    results
  end

  def self.test_configurator_configure
    puts
    puts "-" * 80
    puts "TESTING Configurator CLASS - CONFIGURE METHOD"
    puts "-" * 80
    results = []

    test_case("Configure method with valid keys", results) do
      configurator = MyApplicationVikovan::Configurator.new
      configurator.configure(run_website_parser: 1, run_save_to_csv: 1)
      raise "run_website_parser should be 1" unless configurator.config[:run_website_parser] == 1
      raise "run_save_to_csv should be 1" unless configurator.config[:run_save_to_csv] == 1
      raise "Other values should remain 0" unless configurator.config[:run_save_to_json] == 0
      true
    end

    test_case("Configure method with single parameter", results) do
      configurator = MyApplicationVikovan::Configurator.new
      configurator.configure(run_save_to_json: 1)
      raise "run_save_to_json should be 1" unless configurator.config[:run_save_to_json] == 1
      raise "Other values should remain 0" unless configurator.config[:run_website_parser] == 0
      true
    end

    test_case("Configure method with all parameters", results) do
      configurator = MyApplicationVikovan::Configurator.new
      configurator.configure(
        run_website_parser: 1,
        run_save_to_csv: 1,
        run_save_to_json: 1,
        run_save_to_yaml: 1,
        run_save_to_sqlite: 1,
        run_save_to_mongodb: 1
      )
      raise "All values should be 1" unless configurator.config.values.all? { |v| v == 1 }
      true
    end

    test_case("Configure method with invalid key", results) do
      configurator = MyApplicationVikovan::Configurator.new
      initial_config = configurator.config.dup
      configurator.configure(invalid_key: 1)
      raise "Config should not change with invalid key" unless configurator.config == initial_config
      true
    end

    test_case("Configure method with mixed valid and invalid keys", results) do
      configurator = MyApplicationVikovan::Configurator.new
      configurator.configure(run_website_parser: 1, invalid_key: 999)
      raise "run_website_parser should be updated" unless configurator.config[:run_website_parser] == 1
      raise "invalid_key should not be added" if configurator.config.key?(:invalid_key)
      true
    end

    test_case("Configure method with empty hash", results) do
      configurator = MyApplicationVikovan::Configurator.new
      initial_config = configurator.config.dup
      configurator.configure({})
      raise "Config should not change with empty hash" unless configurator.config == initial_config
      true
    end

    test_case("Configure method updates values multiple times", results) do
      configurator = MyApplicationVikovan::Configurator.new
      configurator.configure(run_save_to_csv: 1)
      configurator.configure(run_save_to_csv: 0)
      configurator.configure(run_save_to_csv: 1)
      raise "run_save_to_csv should be 1" unless configurator.config[:run_save_to_csv] == 1
      true
    end

    results
  end

  def self.test_configurator_available_methods
    puts
    puts "-" * 80
    puts "TESTING Configurator CLASS - AVAILABLE_METHODS CLASS METHOD"
    puts "-" * 80
    results = []

    test_case("available_methods is a class method", results) do
      raise "available_methods should be a class method" unless MyApplicationVikovan::Configurator.respond_to?(:available_methods)
      true
    end

    test_case("available_methods returns array of symbols", results) do
      methods = MyApplicationVikovan::Configurator.available_methods
      raise "available_methods should return array" unless methods.is_a?(Array)
      raise "All methods should be symbols" unless methods.all? { |m| m.is_a?(Symbol) }
      true
    end

    test_case("available_methods returns all configuration keys", results) do
      methods = MyApplicationVikovan::Configurator.available_methods
      expected_keys = [:run_website_parser, :run_save_to_csv, :run_save_to_json, 
                       :run_save_to_yaml, :run_save_to_sqlite, :run_save_to_mongodb]
      raise "available_methods should return all keys" unless methods.sort == expected_keys.sort
      true
    end

    test_case("available_methods returns 6 keys", results) do
      methods = MyApplicationVikovan::Configurator.available_methods
      raise "available_methods should return 6 keys" unless methods.length == 6
      true
    end

    test_case("available_methods can be called without instance", results) do
      methods = MyApplicationVikovan::Configurator.available_methods
      raise "Should return methods without creating instance" unless methods.is_a?(Array)
      true
    end

    results
  end

  def self.test_configurator_logging
    puts
    puts "-" * 80
    puts "TESTING Configurator CLASS - LOGGING"
    puts "-" * 80
    results = []

    test_case("Configurator initialization logging", results) do
      log_file = File.join('logs', 'app.log')
      initial_size = File.exist?(log_file) ? File.size(log_file) : 0
      configurator = MyApplicationVikovan::Configurator.new
      raise "Log file should exist" unless File.exist?(log_file)
      raise "Log file should grow" unless File.size(log_file) > initial_size
      log_content = File.read(log_file)
      raise "Log should contain initialization message" unless log_content.include?("Configurator initialized with default configuration")
      true
    end

    test_case("Configurator configure logging", results) do
      log_file = File.join('logs', 'app.log')
      configurator = MyApplicationVikovan::Configurator.new
      configurator.configure(run_website_parser: 1, run_save_to_csv: 1)
      log_content = File.read(log_file)
      raise "Log should contain starting message" unless log_content.include?("Configurator: Starting configuration")
      raise "Log should contain update messages" unless log_content.include?("Configurator: Updated")
      raise "Log should contain completion message" unless log_content.include?("Configurator: Configuration completed")
      true
    end

    test_case("Configurator configure logs parameter updates", results) do
      log_file = File.join('logs', 'app.log')
      configurator = MyApplicationVikovan::Configurator.new
      configurator.configure(run_save_to_json: 1)
      log_content = File.read(log_file)
      raise "Log should contain run_save_to_json update" unless log_content.include?("Updated run_save_to_json")
      true
    end

    test_case("Configurator configure logs invalid keys", results) do
      log_file = File.join('logs', 'app.log')
      error_log_file = File.join('logs', 'error.log')
      configurator = MyApplicationVikovan::Configurator.new
      configurator.configure(invalid_key: 999)
      log_content = File.read(log_file)
      error_log_content = File.read(error_log_file)
      raise "Error log should contain invalid key message" unless error_log_content.include?("Invalid configuration key 'invalid_key'")
      raise "App log should contain invalid key info in completion message" unless log_content.include?("invalid key(s) ignored")
      true
    end

    test_case("Configurator configure logs parameter count", results) do
      log_file = File.join('logs', 'app.log')
      configurator = MyApplicationVikovan::Configurator.new
      configurator.configure(run_website_parser: 1, run_save_to_csv: 1, run_save_to_yaml: 1)
      log_content = File.read(log_file)
      raise "Log should mention 3 parameter(s)" unless log_content.include?("3 parameter(s)")
      true
    end

    results
  end

  def self.test_case(name, results)
    print "Testing: #{name}... "
    begin
      result = yield
      if result
        puts "PASSED"
        results << { name: name, status: :passed }
      else
        puts "FAILED"
        results << { name: name, status: :failed, error: "Test returned false" }
      end
    rescue StandardError => e
      puts "FAILED: #{e.message}"
      results << { name: name, status: :failed, error: e.message }
    end
  end

  def self.print_summary(results)
    puts
    puts "=" * 80
    puts "TEST SUMMARY"
    puts "=" * 80

    total_tests = 0
    total_passed = 0
    total_failed = 0

    results.each do |category, tests|
      passed = tests.count { |t| t[:status] == :passed }
      failed = tests.count { |t| t[:status] == :failed }
      total = tests.count

      puts
      puts "#{category.to_s.upcase.gsub('_', ' ')}:"
      puts "  Total: #{total}"
      puts "  Passed: #{passed}"
      puts "  Failed: #{failed}"

      if failed > 0
        puts "  Failed tests:"
        tests.select { |t| t[:status] == :failed }.each do |test|
          puts "    - #{test[:name]}: #{test[:error]}"
        end
      end

      total_tests += total
      total_passed += passed
      total_failed += failed
    end

    puts
    puts "-" * 80
    puts "OVERALL:"
    puts "  Total Tests: #{total_tests}"
    puts "  Passed: #{total_passed}"
    puts "  Failed: #{total_failed}"
    puts "  Success Rate: #{total_tests > 0 ? ((total_passed.to_f / total_tests) * 100).round(2) : 0}%"
    puts "=" * 80
  end
end

if __FILE__ == $PROGRAM_NAME
  TestConfigurator.run_all_tests
end

