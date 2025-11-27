# frozen_string_literal: true

require_relative 'app_config_loader'
require_relative 'my_application_vikovan'

puts "Application Initialization"
puts

loader = AppConfigLoader.new

puts "Loading libraries..."
system_libs = ['date', 'time']
loader.load_libs(system_libs, 'libs')
puts "System libraries loaded: #{system_libs.join(', ')}"
puts

puts "Loading configurations..."
config = loader.config('config/default_config.yaml', 'config/yaml_config')
puts "Configurations loaded successfully"
puts

puts "Displaying configuration data..."
puts "--- Configuration Data (JSON format) ---"
loader.pretty_print_config_data(config)
puts

puts "Initializing logger..."
MyApplicationVikovan::LoggerManager.initialize_logger(config)
if MyApplicationVikovan::LoggerManager.logger
  puts "Logger initialized successfully"
  puts "Logger level: #{MyApplicationVikovan::LoggerManager.logger.level}"
else
  puts "Warning: Logger initialization failed"
end
puts

puts "Testing logging functionality..."
MyApplicationVikovan::LoggerManager.log_processed_file("Application started successfully")
MyApplicationVikovan::LoggerManager.log_processed_file("Configuration files loaded")
MyApplicationVikovan::LoggerManager.log_error("Test error message for verification")
puts "Logging test completed. Check logs/app.log and logs/error.log"
puts

puts "Initialization Complete"

