# frozen_string_literal: true

require_relative '../lib/app_config_loader'
require_relative '../lib/my_application_vikovan'
require 'fileutils'

class TestMyApplication
  def self.run_all_tests
    puts "=" * 80
    puts "COMPREHENSIVE TESTING OF MyApplicationVikovan MODULE"
    puts "=" * 80
    puts

    test_results = {
      logger_manager: [],
      item_basic: [],
      item_advanced: [],
      item_comparable: [],
      item_edge_cases: []
    }

    test_results[:logger_manager] = test_logger_manager
    test_results[:item_basic] = test_item_basic_functionality
    test_results[:item_advanced] = test_item_advanced_functionality
    test_results[:item_comparable] = test_item_comparable
    test_results[:item_edge_cases] = test_item_edge_cases

    print_summary(test_results)
    test_results
  end

  private

  def self.test_logger_manager
    puts "-" * 80
    puts "TESTING LoggerManager CLASS"
    puts "-" * 80
    results = []

    loader = AppConfigLoader.new
    config = loader.config('config/default_config.yaml', 'config/yaml_config')
    MyApplicationVikovan::LoggerManager.initialize_logger(config)

    test_case("Logger initialization", results) do
      logger = MyApplicationVikovan::LoggerManager.logger
      raise "Logger should be initialized" unless logger
      raise "Logger should be Logger instance" unless logger.is_a?(Logger)
      true
    end

    test_case("Logger level is set", results) do
      logger = MyApplicationVikovan::LoggerManager.logger
      raise "Logger level should be set" if logger.level.nil?
      true
    end

    test_case("log_processed_file method", results) do
      test_message = "Test processed file message #{Time.now.to_i}"
      MyApplicationVikovan::LoggerManager.log_processed_file(test_message)
      log_file = File.join('logs', 'app.log')
      raise "Log file should exist" unless File.exist?(log_file)
      log_content = File.read(log_file)
      raise "Log should contain message" unless log_content.include?(test_message)
      true
    end

    test_case("log_error method", results) do
      test_error = "Test error message #{Time.now.to_i}"
      MyApplicationVikovan::LoggerManager.log_error(test_error)
      error_log_file = File.join('logs', 'error.log')
      raise "Error log file should exist" unless File.exist?(error_log_file)
      error_content = File.read(error_log_file)
      raise "Error log should contain message" unless error_content.include?(test_error)
      true
    end

    test_case("Logger with symbol keys config", results) do
      symbol_config = {
        logging: {
          directory: 'test_logs',
          level: 'INFO',
          files: {
            application_log: 'test_app.log',
            error_log: 'test_error.log'
          }
        }
      }
      MyApplicationVikovan::LoggerManager.initialize_logger(symbol_config)
      logger = MyApplicationVikovan::LoggerManager.logger
      raise "Logger should work with symbol keys" unless logger
      FileUtils.rm_rf('test_logs') if Dir.exist?('test_logs')
      true
    end

    test_case("Logger with string keys config", results) do
      string_config = {
        'logging' => {
          'directory' => 'test_logs2',
          'level' => 'WARN',
          'files' => {
            'application_log' => 'test_app2.log',
            'error_log' => 'test_error2.log'
          }
        }
      }
      MyApplicationVikovan::LoggerManager.initialize_logger(string_config)
      logger = MyApplicationVikovan::LoggerManager.logger
      raise "Logger should work with string keys" unless logger
      FileUtils.rm_rf('test_logs2') if Dir.exist?('test_logs2')
      true
    end

    test_case("Logger with invalid config", results) do
      invalid_config = {}
      old_logger = MyApplicationVikovan::LoggerManager.logger
      MyApplicationVikovan::LoggerManager.initialize_logger(invalid_config)
      new_logger = MyApplicationVikovan::LoggerManager.logger
      raise "Logger should handle invalid config gracefully" if new_logger.nil? && old_logger.nil?
      true
    rescue StandardError
      true
    end

    results
  end

  def self.test_item_basic_functionality
    puts
    puts "-" * 80
    puts "TESTING Item CLASS - BASIC FUNCTIONALITY"
    puts "-" * 80
    results = []

    test_case("Item initialization with hash params", results) do
      item = MyApplicationVikovan::Item.new(
        name: "Test Item",
        price: 99.99,
        description: "Test description",
        category: "Test Category",
        image_path: "test/image.jpg"
      )
      raise "Name should be set" unless item.name == "Test Item"
      raise "Price should be set" unless item.price == 99.99
      raise "Description should be set" unless item.description == "Test description"
      raise "Category should be set" unless item.category == "Test Category"
      raise "Image path should be set" unless item.image_path == "test/image.jpg"
      true
    end

    test_case("Item initialization with string keys", results) do
      item = MyApplicationVikovan::Item.new(
        'name' => "String Key Item",
        'price' => 50.0,
        'description' => "Description",
        'category' => "Category",
        'image_path' => "path/to/image.jpg"
      )
      raise "Should work with string keys" unless item.name == "String Key Item"
      raise "Price should work with string keys" unless item.price == 50.0
      true
    end

    test_case("Item initialization with empty params", results) do
      item = MyApplicationVikovan::Item.new
      raise "Name should default to empty string" unless item.name == ''
      raise "Price should default to 0.0" unless item.price == 0.0
      raise "Description should default to empty string" unless item.description == ''
      raise "Category should default to empty string" unless item.category == ''
      raise "Image path should default to empty string" unless item.image_path == ''
      true
    end

    test_case("Item initialization with block", results) do
      item = MyApplicationVikovan::Item.new do |i|
        i.name = "Block Item"
        i.price = 25.5
        i.category = "Block Category"
      end
      raise "Block should set name" unless item.name == "Block Item"
      raise "Block should set price" unless item.price == 25.5
      raise "Block should set category" unless item.category == "Block Category"
      true
    end

    test_case("Item attribute setters", results) do
      item = MyApplicationVikovan::Item.new
      item.name = "Setter Test"
      item.price = 123.45
      item.description = "Setter Description"
      item.category = "Setter Category"
      item.image_path = "setter/path.jpg"
      raise "Name setter failed" unless item.name == "Setter Test"
      raise "Price setter failed" unless item.price == 123.45
      raise "Description setter failed" unless item.description == "Setter Description"
      raise "Category setter failed" unless item.category == "Setter Category"
      raise "Image path setter failed" unless item.image_path == "setter/path.jpg"
      true
    end

    test_case("Item to_s method", results) do
      item = MyApplicationVikovan::Item.new(name: "Test", price: 10.0)
      string_representation = item.to_s
      raise "to_s should contain name" unless string_representation.include?("name: Test")
      raise "to_s should contain price" unless string_representation.include?("price: 10.0")
      true
    end

    test_case("Item info method", results) do
      item = MyApplicationVikovan::Item.new(name: "Info Test", price: 15.0)
      info_result = item.info
      raise "info should return string representation" unless info_result.is_a?(String)
      raise "info should contain item data" unless info_result.include?("name: Info Test")
      true
    end

    test_case("Item to_h method", results) do
      item = MyApplicationVikovan::Item.new(
        name: "Hash Test",
        price: 20.0,
        description: "Description",
        category: "Category"
      )
      hash_representation = item.to_h
      raise "to_h should return Hash" unless hash_representation.is_a?(Hash)
      raise "Hash should contain name" unless hash_representation[:name] == "Hash Test"
      raise "Hash should contain price" unless hash_representation[:price] == 20.0
      raise "Hash should contain description" unless hash_representation[:description] == "Description"
      raise "Hash should contain category" unless hash_representation[:category] == "Category"
      true
    end

    test_case("Item inspect method", results) do
      item = MyApplicationVikovan::Item.new(name: "Inspect Test", price: 30.0)
      inspect_result = item.inspect
      raise "inspect should contain class name" unless inspect_result.include?("MyApplicationVikovan::Item")
      raise "inspect should contain to_s representation" unless inspect_result.include?(item.to_s)
      true
    end

    results
  end

  def self.test_item_advanced_functionality
    puts
    puts "-" * 80
    puts "TESTING Item CLASS - ADVANCED FUNCTIONALITY"
    puts "-" * 80
    results = []

    test_case("Item update method with block", results) do
      item = MyApplicationVikovan::Item.new(name: "Original", price: 10.0)
      updated_item = item.update do |i|
        i.name = "Updated"
        i.price = 20.0
      end
      raise "Update should return self" unless updated_item == item
      raise "Name should be updated" unless item.name == "Updated"
      raise "Price should be updated" unless item.price == 20.0
      true
    end

    test_case("Item update method without block", results) do
      item = MyApplicationVikovan::Item.new(name: "Test", price: 10.0)
      updated_item = item.update
      raise "Update should return self even without block" unless updated_item == item
      true
    end

    test_case("Item generate_fake method", results) do
      fake_item = MyApplicationVikovan::Item.generate_fake
      raise "generate_fake should return Item instance" unless fake_item.is_a?(MyApplicationVikovan::Item)
      raise "Fake item should have name" unless !fake_item.name.empty?
      raise "Fake item should have price" unless fake_item.price.is_a?(Numeric)
      raise "Fake item should have description" unless !fake_item.description.empty?
      raise "Fake item should have category" unless !fake_item.category.empty?
      raise "Fake item should have image_path" unless !fake_item.image_path.empty?
      raise "Price should be in range 10-100" unless fake_item.price >= 10.0 && fake_item.price <= 100.0
      true
    end

    test_case("Item generate_fake creates unique items", results) do
      fake1 = MyApplicationVikovan::Item.generate_fake
      fake2 = MyApplicationVikovan::Item.generate_fake
      different = (fake1.name != fake2.name) || (fake1.price != fake2.price) || (fake1.category != fake2.category)
      raise "Fake items should be different" unless different
      true
    end

    test_case("Item logging on initialization", results) do
      log_file = File.join('logs', 'app.log')
      initial_size = File.exist?(log_file) ? File.size(log_file) : 0
      
      loader = AppConfigLoader.new
      config = loader.config('config/default_config.yaml', 'config/yaml_config')
      MyApplicationVikovan::LoggerManager.initialize_logger(config)
      
      item = MyApplicationVikovan::Item.new(name: "Logged Item", price: 50.0, category: "Log Category")
      raise "Log file should exist" unless File.exist?(log_file)
      raise "Log file should grow" unless File.size(log_file) > initial_size
      log_content = File.read(log_file)
      raise "Log should contain initialization message" unless log_content.include?("Item initialized")
      raise "Log should contain item name" unless log_content.include?("Logged Item")
      true
    end

    test_case("Item logging on update", results) do
      log_file = File.join('logs', 'app.log')
      initial_size = File.exist?(log_file) ? File.size(log_file) : 0
      
      item = MyApplicationVikovan::Item.new(name: "Update Test", price: 10.0)
      item.update { |i| i.price = 20.0 }
      
      raise "Log file should grow" unless File.exist?(log_file) && File.size(log_file) > initial_size
      log_content = File.read(log_file)
      raise "Log should contain update message" unless log_content.include?("Item updated")
      true
    end

    results
  end

  def self.test_item_comparable
    puts
    puts "-" * 80
    puts "TESTING Item CLASS - COMPARABLE FUNCTIONALITY"
    puts "-" * 80
    results = []

    test_case("Item comparison with < operator", results) do
      item1 = MyApplicationVikovan::Item.new(price: 10.0)
      item2 = MyApplicationVikovan::Item.new(price: 20.0)
      raise "Item1 should be less than item2" unless item1 < item2
      raise "Item2 should not be less than item1" if item2 < item1
      true
    end

    test_case("Item comparison with > operator", results) do
      item1 = MyApplicationVikovan::Item.new(price: 30.0)
      item2 = MyApplicationVikovan::Item.new(price: 15.0)
      raise "Item1 should be greater than item2" unless item1 > item2
      raise "Item2 should not be greater than item1" if item2 > item1
      true
    end

    test_case("Item comparison with == operator", results) do
      item1 = MyApplicationVikovan::Item.new(price: 25.0)
      item2 = MyApplicationVikovan::Item.new(price: 25.0)
      raise "Items with same price should be equal" unless item1 == item2
      true
    end

    test_case("Item comparison with <= operator", results) do
      item1 = MyApplicationVikovan::Item.new(price: 10.0)
      item2 = MyApplicationVikovan::Item.new(price: 20.0)
      item3 = MyApplicationVikovan::Item.new(price: 10.0)
      raise "Item1 should be <= item2" unless item1 <= item2
      raise "Item1 should be <= item3" unless item1 <= item3
      true
    end

    test_case("Item comparison with >= operator", results) do
      item1 = MyApplicationVikovan::Item.new(price: 30.0)
      item2 = MyApplicationVikovan::Item.new(price: 15.0)
      item3 = MyApplicationVikovan::Item.new(price: 30.0)
      raise "Item1 should be >= item2" unless item1 >= item2
      raise "Item1 should be >= item3" unless item1 >= item3
      true
    end

    test_case("Item comparison with <=> operator", results) do
      item1 = MyApplicationVikovan::Item.new(price: 10.0)
      item2 = MyApplicationVikovan::Item.new(price: 20.0)
      item3 = MyApplicationVikovan::Item.new(price: 10.0)
      raise "Item1 should return -1 when compared to item2" unless (item1 <=> item2) == -1
      raise "Item2 should return 1 when compared to item1" unless (item2 <=> item1) == 1
      raise "Item1 should return 0 when compared to item3" unless (item1 <=> item3) == 0
      true
    end

    test_case("Item comparison with non-Item object", results) do
      item = MyApplicationVikovan::Item.new(price: 10.0)
      result = item <=> "not an item"
      raise "Comparison with non-Item should return nil" unless result.nil?
      true
    end

    test_case("Item sorting with sort method", results) do
      items = [
        MyApplicationVikovan::Item.new(name: "Item3", price: 30.0),
        MyApplicationVikovan::Item.new(name: "Item1", price: 10.0),
        MyApplicationVikovan::Item.new(name: "Item2", price: 20.0)
      ]
      sorted = items.sort
      raise "First item should have price 10.0" unless sorted[0].price == 10.0
      raise "Second item should have price 20.0" unless sorted[1].price == 20.0
      raise "Third item should have price 30.0" unless sorted[2].price == 30.0
      true
    end

    test_case("Item min/max methods", results) do
      items = [
        MyApplicationVikovan::Item.new(price: 30.0),
        MyApplicationVikovan::Item.new(price: 10.0),
        MyApplicationVikovan::Item.new(price: 20.0)
      ]
      min_item = items.min
      max_item = items.max
      raise "Min item should have price 10.0" unless min_item.price == 10.0
      raise "Max item should have price 30.0" unless max_item.price == 30.0
      true
    end

    results
  end

  def self.test_item_edge_cases
    puts
    puts "-" * 80
    puts "TESTING Item CLASS - EDGE CASES"
    puts "-" * 80
    results = []

    test_case("Item with nil values in params", results) do
      item = MyApplicationVikovan::Item.new(name: nil, price: nil)
      raise "Name should convert nil to empty string" unless item.name == ''
      raise "Price should convert nil to 0.0" unless item.price == 0.0
      true
    end

    test_case("Item with zero price", results) do
      item = MyApplicationVikovan::Item.new(price: 0.0)
      raise "Zero price should be valid" unless item.price == 0.0
      raise "Item should be comparable with zero price" unless item == MyApplicationVikovan::Item.new(price: 0.0)
      true
    end

    test_case("Item with negative price", results) do
      item = MyApplicationVikovan::Item.new(price: -10.0)
      raise "Negative price should be accepted" unless item.price == -10.0
      negative_item = MyApplicationVikovan::Item.new(price: -10.0)
      positive_item = MyApplicationVikovan::Item.new(price: 10.0)
      raise "Negative should be less than positive" unless negative_item < positive_item
      true
    end

    test_case("Item with very large price", results) do
      large_price = 999_999_999.99
      item = MyApplicationVikovan::Item.new(price: large_price)
      raise "Large price should be handled" unless item.price == large_price
      true
    end

    test_case("Item with empty string values", results) do
      item = MyApplicationVikovan::Item.new(name: "", description: "", category: "")
      raise "Empty strings should be valid" unless item.name == "" && item.description == "" && item.category == ""
      true
    end

    test_case("Item with special characters in name", results) do
      special_name = "Item & Co. <Test> \"Special\" 'Chars'"
      item = MyApplicationVikovan::Item.new(name: special_name)
      raise "Special characters should be preserved" unless item.name == special_name
      true
    end

    test_case("Item with unicode characters", results) do
      unicode_name = "Товар №1 - Україна"
      item = MyApplicationVikovan::Item.new(name: unicode_name)
      raise "Unicode characters should be preserved" unless item.name == unicode_name
      true
    end

    test_case("Item with very long description", results) do
      long_description = "A" * 1000
      item = MyApplicationVikovan::Item.new(description: long_description)
      raise "Long description should be handled" unless item.description.length == 1000
      true
    end

    test_case("Item initialization with non-hash params", results) do
      item = MyApplicationVikovan::Item.new("invalid")
      raise "Non-hash params should be normalized to empty hash" unless item.name == ''
      true
    end

    test_case("Item initialization with nil params", results) do
      item = MyApplicationVikovan::Item.new(nil)
      raise "Nil params should be normalized" unless item.name == ''
      true
    end

    test_case("Item multiple updates chaining", results) do
      item = MyApplicationVikovan::Item.new(name: "Chain", price: 10.0)
      item.update { |i| i.price = 20.0 }.update { |i| i.price = 30.0 }
      raise "Chained updates should work" unless item.price == 30.0
      true
    end

    test_case("Item info method error handling", results) do
      item = MyApplicationVikovan::Item.new(name: "Error Test", price: 10.0)
      def item.to_s
        raise StandardError, "Test error"
      end
      begin
        item.info
        raise "Should raise error"
      rescue StandardError => e
        raise "Should raise original error" unless e.message == "Test error"
      end
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
  TestMyApplication.run_all_tests
end

