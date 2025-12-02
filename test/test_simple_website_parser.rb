# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('lib', __dir__)

require 'app_config_loader'
require 'web_parser'

config_loader = AppConfigLoader.new
config = config_loader.config('config/default_config.yaml', 'config/yaml_config')

MyApplicationVikovan::LoggerManager.initialize_logger(config)

parser = MyApplicationVikovan::WebParser::SimpleWebsiteParser.new(config)

start_page = parser.config['start_page'] || parser.config[:start_page]
base_url = parser.config['base_url'] || parser.config[:base_url]

puts "=== SimpleWebsiteParser tests ==="
puts "Start page: #{start_page}"
puts "Base URL:  #{base_url}"

valid_url_result = parser.send(:check_url_response, start_page)
puts "check_url_response(VALID) => #{valid_url_result}"

invalid_url = "#{base_url}/non-existing-page-123456.html"
invalid_url_result = parser.send(:check_url_response, invalid_url)
puts "check_url_response(INVALID) => #{invalid_url_result}"

page = parser.agent.get(start_page)
links = parser.extract_products_links(page)
puts "extract_products_links => count=#{links.length}"
puts "First link: #{links.first}" unless links.empty?

initial_items = parser.item_collection.items.length
if links.any?
  test_link = links.first
  puts "Testing parse_product_page with: #{test_link}"
  result = parser.parse_product_page(test_link)
  puts "parse_product_page returned: #{result.inspect}"
end
after_one_item = parser.item_collection.items.length
puts "parse_product_page(first) => items before=#{initial_items}, after=#{after_one_item}"
if after_one_item > initial_items
  item = parser.item_collection.items.last
  puts "  Last item: name=#{item.name}, price=#{item.price}, category=#{item.category}"
end

parser.config['concurrency'] = 2
puts "Running start_parse with concurrency=#{parser.config['concurrency']}..."
success = parser.start_parse
final_items = parser.item_collection.items.length
puts "start_parse => success=#{success}, total items=#{final_items}"

puts "=== Tests finished ==="


