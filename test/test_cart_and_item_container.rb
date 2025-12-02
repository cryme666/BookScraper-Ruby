# frozen_string_literal: true

require_relative '../lib/app_config_loader'
require_relative '../lib/my_application_vikovan'
require_relative '../lib/item_container'
require 'fileutils'

class TestCartAndItemContainer
  def self.run_all_tests
    puts "=" * 80
    puts "COMPREHENSIVE TESTING OF Cart CLASS AND ItemContainer MODULE"
    puts "=" * 80
    puts

    loader = AppConfigLoader.new
    config = loader.config('config/default_config.yaml', 'config/yaml_config')
    MyApplicationVikovan::LoggerManager.initialize_logger(config)

    test_results = {
      cart_basic: [],
      item_container_basic: [],
      cart_save_methods: [],
      cart_enumerable: [],
      cart_logging: [],
      item_container_logging: []
    }

    test_results[:cart_basic] = test_cart_basic_functionality
    test_results[:item_container_basic] = test_item_container_basic
    test_results[:cart_save_methods] = test_cart_save_methods
    test_results[:cart_enumerable] = test_cart_enumerable_methods
    test_results[:cart_logging] = test_cart_logging
    test_results[:item_container_logging] = test_item_container_logging

    print_summary(test_results)
    test_results
  end

  private

  def self.test_cart_basic_functionality
    puts "-" * 80
    puts "TESTING Cart CLASS - BASIC FUNCTIONALITY"
    puts "-" * 80
    results = []

    test_case("Cart initialization", results) do
      cart = MyApplicationVikovan::Cart.new
      raise "Cart should be initialized" unless cart.is_a?(MyApplicationVikovan::Cart)
      raise "Items should be empty array" unless cart.items == []
      true
    end

    test_case("Cart includes Enumerable", results) do
      cart = MyApplicationVikovan::Cart.new
      raise "Cart should include Enumerable" unless cart.is_a?(Enumerable)
      true
    end

    test_case("Cart has items attribute", results) do
      cart = MyApplicationVikovan::Cart.new
      cart.items = [MyApplicationVikovan::Item.new(name: "Test", price: 10.0)]
      raise "Items should be settable" unless cart.items.length == 1
      true
    end

    test_case("Cart each method works", results) do
      cart = MyApplicationVikovan::Cart.new
      item1 = MyApplicationVikovan::Item.new(name: "Item1", price: 10.0)
      item2 = MyApplicationVikovan::Item.new(name: "Item2", price: 20.0)
      cart.items = [item1, item2]
      collected = []
      cart.each { |item| collected << item.name }
      raise "Each should iterate over items" unless collected == ["Item1", "Item2"]
      true
    end

    results
  end

  def self.test_item_container_basic
    puts
    puts "-" * 80
    puts "TESTING ItemContainer MODULE - BASIC FUNCTIONALITY"
    puts "-" * 80
    results = []

    unless MyApplicationVikovan::Cart.included_modules.include?(ItemContainer)
      MyApplicationVikovan::Cart.class_eval do
        include ItemContainer
      end
    end

    test_case("Cart includes ItemContainer", results) do
      cart = MyApplicationVikovan::Cart.new
      raise "Cart should include ItemContainer" unless cart.class.included_modules.include?(ItemContainer)
      true
    end

    test_case("ItemContainer class_info method", results) do
      info = MyApplicationVikovan::Cart.class_info
      raise "class_info should return hash" unless info.is_a?(Hash)
      raise "class_info should contain class_name" unless info[:class_name]
      raise "class_info should contain version" unless info[:version]
      raise "Version should be 1.0.0" unless info[:version] == '1.0.0'
      true
    end

    test_case("ItemContainer instance_count method", results) do
      initial_count = MyApplicationVikovan::Cart.instance_count
      cart1 = MyApplicationVikovan::Cart.new
      cart2 = MyApplicationVikovan::Cart.new
      count = MyApplicationVikovan::Cart.instance_count
      raise "Instance count should increment" unless count >= initial_count + 2
      true
    end

    test_case("ItemContainer add_item method", results) do
      cart = MyApplicationVikovan::Cart.new
      item = MyApplicationVikovan::Item.new(name: "Test Item", price: 99.99)
      cart.add_item(item)
      raise "Item should be added" unless cart.items.include?(item)
      raise "Items count should be 1" unless cart.items.length == 1
      true
    end

    test_case("ItemContainer remove_item method", results) do
      cart = MyApplicationVikovan::Cart.new
      item1 = MyApplicationVikovan::Item.new(name: "Item1", price: 10.0)
      item2 = MyApplicationVikovan::Item.new(name: "Item2", price: 20.0)
      cart.add_item(item1)
      cart.add_item(item2)
      cart.remove_item(item1)
      raise "Item1 should be removed" if cart.items.include?(item1)
      raise "Item2 should remain" unless cart.items.include?(item2)
      raise "Items count should be 1" unless cart.items.length == 1
      true
    end

    test_case("ItemContainer delete_items method", results) do
      cart = MyApplicationVikovan::Cart.new
      cart.add_item(MyApplicationVikovan::Item.new(name: "Item1", price: 10.0))
      cart.add_item(MyApplicationVikovan::Item.new(name: "Item2", price: 20.0))
      cart.delete_items
      raise "All items should be deleted" unless cart.items.empty?
      true
    end

    test_case("ItemContainer generate_test_items method", results) do
      cart = MyApplicationVikovan::Cart.new
      cart.generate_test_items(5)
      raise "Should generate 5 items" unless cart.items.length == 5
      raise "All items should be Item instances" unless cart.items.all? { |item| item.is_a?(MyApplicationVikovan::Item) }
      true
    end

    test_case("ItemContainer generate_test_items default count", results) do
      cart = MyApplicationVikovan::Cart.new
      cart.generate_test_items
      raise "Should generate 5 items by default" unless cart.items.length == 5
      true
    end

    test_case("ItemContainer show_all_items method", results) do
      cart = MyApplicationVikovan::Cart.new
      cart.add_item(MyApplicationVikovan::Item.new(name: "Test Item", price: 99.99))
      raise "Should respond to show_all_items" unless cart.respond_to?(:show_all_items)
      cart.show_all_items
      true
    end

    results
  end

  def self.test_cart_save_methods
    puts
    puts "-" * 80
    puts "TESTING Cart CLASS - SAVE METHODS"
    puts "-" * 80
    results = []

    test_case("Cart save_to_file method", results) do
      cart = MyApplicationVikovan::Cart.new
      cart.add_item(MyApplicationVikovan::Item.new(name: "Test Item", price: 99.99, description: "Test desc", category: "Test Cat"))
      file_path = 'test_output/save_test.txt'
      cart.save_to_file(file_path)
      raise "File should be created" unless File.exist?(file_path)
      content = File.read(file_path)
      raise "File should contain item info" unless content.include?("Test Item")
      FileUtils.rm_rf('test_output') if Dir.exist?('test_output')
      true
    end

    test_case("Cart save_to_json method", results) do
      cart = MyApplicationVikovan::Cart.new
      cart.add_item(MyApplicationVikovan::Item.new(name: "JSON Item", price: 50.0))
      file_path = 'test_output/save_test.json'
      cart.save_to_json(file_path)
      raise "JSON file should be created" unless File.exist?(file_path)
      content = File.read(file_path)
      raise "JSON file should contain item data" unless content.include?("JSON Item")
      parsed = JSON.parse(content)
      raise "JSON should be valid array" unless parsed.is_a?(Array)
      raise "JSON array should have 1 item" unless parsed.length == 1
      FileUtils.rm_rf('test_output') if Dir.exist?('test_output')
      true
    end

    test_case("Cart save_to_csv method", results) do
      cart = MyApplicationVikovan::Cart.new
      cart.add_item(MyApplicationVikovan::Item.new(name: "CSV Item", price: 75.0, description: "CSV Desc", category: "CSV Cat"))
      file_path = 'test_output/save_test.csv'
      cart.save_to_csv(file_path)
      raise "CSV file should be created" unless File.exist?(file_path)
      content = File.read(file_path)
      raise "CSV should contain headers" unless content.include?("name,price")
      raise "CSV should contain item name" unless content.include?("CSV Item")
      FileUtils.rm_rf('test_output') if Dir.exist?('test_output')
      true
    end

    test_case("Cart save_to_csv with empty cart", results) do
      cart = MyApplicationVikovan::Cart.new
      file_path = 'test_output/empty_test.csv'
      cart.save_to_csv(file_path)
      raise "CSV file should not be created for empty cart" if File.exist?(file_path)
      FileUtils.rm_rf('test_output') if Dir.exist?('test_output')
      true
    end

    test_case("Cart save_to_yml method", results) do
      cart = MyApplicationVikovan::Cart.new
      cart.add_item(MyApplicationVikovan::Item.new(name: "YAML Item 1", price: 30.0))
      cart.add_item(MyApplicationVikovan::Item.new(name: "YAML Item 2", price: 40.0))
      dir_path = 'test_output/yml_test'
      cart.save_to_yml(dir_path)
      raise "Directory should be created" unless Dir.exist?(dir_path)
      raise "Should create item_1.yml" unless File.exist?(File.join(dir_path, "item_1.yml"))
      raise "Should create item_2.yml" unless File.exist?(File.join(dir_path, "item_2.yml"))
      content1 = File.read(File.join(dir_path, "item_1.yml"))
      raise "YAML should contain item data" unless content1.include?("YAML Item 1")
      FileUtils.rm_rf('test_output') if Dir.exist?('test_output')
      true
    end

    results
  end

  def self.test_cart_enumerable_methods
    puts
    puts "-" * 80
    puts "TESTING Cart CLASS - Enumerable METHODS"
    puts "-" * 80
    results = []

    test_case("Cart map_items method", results) do
      cart = MyApplicationVikovan::Cart.new
      cart.items = [
        MyApplicationVikovan::Item.new(name: "Item1", price: 10.0),
        MyApplicationVikovan::Item.new(name: "Item2", price: 20.0)
      ]
      prices = cart.map_items { |item| item.price }
      raise "map_items should return array of prices" unless prices == [10.0, 20.0]
      true
    end

    test_case("Cart select_items method", results) do
      cart = MyApplicationVikovan::Cart.new
      cart.items = [
        MyApplicationVikovan::Item.new(name: "Cheap", price: 10.0),
        MyApplicationVikovan::Item.new(name: "Expensive", price: 50.0),
        MyApplicationVikovan::Item.new(name: "Medium", price: 30.0)
      ]
      expensive = cart.select_items { |item| item.price > 25.0 }
      raise "select_items should return 2 items" unless expensive.length == 2
      raise "All selected items should have price > 25" unless expensive.all? { |item| item.price > 25.0 }
      true
    end

    test_case("Cart reject_items method", results) do
      cart = MyApplicationVikovan::Cart.new
      cart.items = [
        MyApplicationVikovan::Item.new(price: 10.0),
        MyApplicationVikovan::Item.new(price: 50.0),
        MyApplicationVikovan::Item.new(price: 30.0)
      ]
      cheap = cart.reject_items { |item| item.price > 25.0 }
      raise "reject_items should return 1 item" unless cheap.length == 1
      raise "Rejected items should have price <= 25" unless cheap.first.price <= 25.0
      true
    end

    test_case("Cart find_item method", results) do
      cart = MyApplicationVikovan::Cart.new
      item_to_find = MyApplicationVikovan::Item.new(name: "Target", price: 25.0)
      cart.items = [
        MyApplicationVikovan::Item.new(name: "Item1", price: 10.0),
        item_to_find,
        MyApplicationVikovan::Item.new(name: "Item3", price: 30.0)
      ]
      found = cart.find_item { |item| item.price == 25.0 }
      raise "find_item should find correct item" unless found == item_to_find
      true
    end

    test_case("Cart reduce_items method", results) do
      cart = MyApplicationVikovan::Cart.new
      cart.items = [
        MyApplicationVikovan::Item.new(price: 10.0),
        MyApplicationVikovan::Item.new(price: 20.0),
        MyApplicationVikovan::Item.new(price: 30.0)
      ]
      total = cart.reduce_items(0) { |sum, item| sum + item.price }
      raise "reduce_items should calculate total" unless total == 60.0
      true
    end

    test_case("Cart all_items? method", results) do
      cart = MyApplicationVikovan::Cart.new
      cart.items = [
        MyApplicationVikovan::Item.new(price: 10.0),
        MyApplicationVikovan::Item.new(price: 20.0),
        MyApplicationVikovan::Item.new(price: 30.0)
      ]
      all_positive = cart.all_items? { |item| item.price > 0 }
      all_expensive = cart.all_items? { |item| item.price > 50.0 }
      raise "all_items? should return true for all positive prices" unless all_positive == true
      raise "all_items? should return false for all expensive" unless all_expensive == false
      true
    end

    test_case("Cart any_item? method", results) do
      cart = MyApplicationVikovan::Cart.new
      cart.items = [
        MyApplicationVikovan::Item.new(price: 10.0),
        MyApplicationVikovan::Item.new(price: 50.0),
        MyApplicationVikovan::Item.new(price: 30.0)
      ]
      has_expensive = cart.any_item? { |item| item.price > 40.0 }
      has_free = cart.any_item? { |item| item.price == 0.0 }
      raise "any_item? should return true for expensive item" unless has_expensive == true
      raise "any_item? should return false for free items" unless has_free == false
      true
    end

    test_case("Cart none_items? method", results) do
      cart = MyApplicationVikovan::Cart.new
      cart.items = [
        MyApplicationVikovan::Item.new(price: 10.0),
        MyApplicationVikovan::Item.new(price: 20.0)
      ]
      no_free = cart.none_items? { |item| item.price == 0.0 }
      no_negative = cart.none_items? { |item| item.price < 0 }
      raise "none_items? should return true when no items match" unless no_free == true
      raise "none_items? should return true when no items match" unless no_negative == true
      true
    end

    test_case("Cart count_items method", results) do
      cart = MyApplicationVikovan::Cart.new
      cart.items = [
        MyApplicationVikovan::Item.new(price: 10.0),
        MyApplicationVikovan::Item.new(price: 50.0),
        MyApplicationVikovan::Item.new(price: 30.0)
      ]
      total_count = cart.count_items
      expensive_count = cart.count_items { |item| item.price > 25.0 }
      raise "count_items should return total count" unless total_count == 3
      raise "count_items with block should return filtered count" unless expensive_count == 2
      true
    end

    test_case("Cart sort_items method", results) do
      cart = MyApplicationVikovan::Cart.new
      cart.items = [
        MyApplicationVikovan::Item.new(name: "Item3", price: 30.0),
        MyApplicationVikovan::Item.new(name: "Item1", price: 10.0),
        MyApplicationVikovan::Item.new(name: "Item2", price: 20.0)
      ]
      sorted = cart.sort_items
      raise "sort_items should sort by price" unless sorted[0].price == 10.0
      raise "sort_items should sort by price" unless sorted[1].price == 20.0
      raise "sort_items should sort by price" unless sorted[2].price == 30.0
      true
    end

    test_case("Cart unique_items method", results) do
      cart = MyApplicationVikovan::Cart.new
      item1 = MyApplicationVikovan::Item.new(name: "Item1", price: 10.0)
      item2 = MyApplicationVikovan::Item.new(name: "Item2", price: 20.0)
      item3 = MyApplicationVikovan::Item.new(name: "Item3", price: 30.0)
      cart.items = [item1, item2, item3]
      unique = cart.unique_items
      raise "unique_items should return all items when all are unique" unless unique.length == 3
      cart.items = [item1, item1, item2]
      unique_dup = cart.unique_items
      raise "unique_items should handle duplicates" unless unique_dup.is_a?(Array)
      true
    end

    results
  end

  def self.test_cart_logging
    puts
    puts "-" * 80
    puts "TESTING Cart CLASS - LOGGING"
    puts "-" * 80
    results = []

    test_case("Cart initialization logging", results) do
      log_file = File.join('logs', 'app.log')
      initial_size = File.exist?(log_file) ? File.size(log_file) : 0
      cart = MyApplicationVikovan::Cart.new
      raise "Log file should exist" unless File.exist?(log_file)
      raise "Log file should grow" unless File.size(log_file) > initial_size
      log_content = File.read(log_file)
      raise "Log should contain initialization message" unless log_content.include?("Cart initialized")
      true
    end

    test_case("Cart save_to_file logging", results) do
      log_file = File.join('logs', 'app.log')
      initial_size = File.exist?(log_file) ? File.size(log_file) : 0
      cart = MyApplicationVikovan::Cart.new
      cart.add_item(MyApplicationVikovan::Item.new(name: "Test", price: 10.0))
      cart.save_to_file('test_output/log_test.txt')
      raise "Log file should grow" unless File.size(log_file) > initial_size
      log_content = File.read(log_file)
      raise "Log should contain save message" unless log_content.include?("Cart: Starting save to file")
      raise "Log should contain success message" unless log_content.include?("Cart: Successfully saved")
      FileUtils.rm_rf('test_output') if Dir.exist?('test_output')
      true
    end

    test_case("Cart save_to_json logging", results) do
      log_file = File.join('logs', 'app.log')
      cart = MyApplicationVikovan::Cart.new
      cart.add_item(MyApplicationVikovan::Item.new(name: "JSON Test", price: 15.0))
      cart.save_to_json('test_output/log_test.json')
      log_content = File.read(log_file)
      raise "Log should contain JSON save message" unless log_content.include?("Cart: Starting save to JSON file")
      FileUtils.rm_rf('test_output') if Dir.exist?('test_output')
      true
    end

    test_case("Cart save_to_csv logging", results) do
      log_file = File.join('logs', 'app.log')
      cart = MyApplicationVikovan::Cart.new
      cart.add_item(MyApplicationVikovan::Item.new(name: "CSV Test", price: 20.0))
      cart.save_to_csv('test_output/log_test.csv')
      log_content = File.read(log_file)
      raise "Log should contain CSV save message" unless log_content.include?("Cart: Starting save to CSV file")
      FileUtils.rm_rf('test_output') if Dir.exist?('test_output')
      true
    end

    test_case("Cart save_to_yml logging", results) do
      log_file = File.join('logs', 'app.log')
      cart = MyApplicationVikovan::Cart.new
      cart.add_item(MyApplicationVikovan::Item.new(name: "YAML Test", price: 25.0))
      cart.save_to_yml('test_output/yml_log_test')
      log_content = File.read(log_file)
      raise "Log should contain YAML save message" unless log_content.include?("Cart: Starting save to YAML directory")
      FileUtils.rm_rf('test_output') if Dir.exist?('test_output')
      true
    end

    results
  end

  def self.test_item_container_logging
    puts
    puts "-" * 80
    puts "TESTING ItemContainer MODULE - LOGGING"
    puts "-" * 80
    results = []

    test_case("ItemContainer add_item logging", results) do
      log_file = File.join('logs', 'app.log')
      cart = MyApplicationVikovan::Cart.new
      item = MyApplicationVikovan::Item.new(name: "Log Test Item", price: 99.99)
      cart.add_item(item)
      log_content = File.read(log_file)
      raise "Log should contain add message" unless log_content.include?("Cart: Item added")
      raise "Log should contain item name" unless log_content.include?("Log Test Item")
      true
    end

    test_case("ItemContainer remove_item logging", results) do
      log_file = File.join('logs', 'app.log')
      cart = MyApplicationVikovan::Cart.new
      item = MyApplicationVikovan::Item.new(name: "Remove Test", price: 50.0)
      cart.add_item(item)
      cart.remove_item(item)
      log_content = File.read(log_file)
      raise "Log should contain remove message" unless log_content.include?("Cart: Item removed")
      raise "Log should contain item name" unless log_content.include?("Remove Test")
      true
    end

    test_case("ItemContainer remove_item logging for non-existent item", results) do
      log_file = File.join('logs', 'app.log')
      cart = MyApplicationVikovan::Cart.new
      item = MyApplicationVikovan::Item.new(name: "Non-existent", price: 30.0)
      cart.remove_item(item)
      log_content = File.read(log_file)
      raise "Log should contain not found message" unless log_content.include?("Cart: Attempted to remove item not found")
      true
    end

    test_case("ItemContainer delete_items logging", results) do
      log_file = File.join('logs', 'app.log')
      cart = MyApplicationVikovan::Cart.new
      cart.add_item(MyApplicationVikovan::Item.new(name: "Item1", price: 10.0))
      cart.add_item(MyApplicationVikovan::Item.new(name: "Item2", price: 20.0))
      cart.delete_items
      log_content = File.read(log_file)
      raise "Log should contain delete message" unless log_content.include?("Cart: All items deleted")
      true
    end

    test_case("ItemContainer generate_test_items logging", results) do
      log_file = File.join('logs', 'app.log')
      cart = MyApplicationVikovan::Cart.new
      cart.generate_test_items(3)
      log_content = File.read(log_file)
      raise "Log should contain generation start message" unless log_content.include?("Cart: Generating")
      raise "Log should contain generation success message" unless log_content.include?("Cart: Successfully generated")
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
  TestCartAndItemContainer.run_all_tests
end

