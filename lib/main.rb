# frozen_string_literal: true

require 'dotenv/load'
require_relative 'app_config_loader'
require_relative 'my_application_vikovan'

loader = AppConfigLoader.new
config = loader.config('config/default_config.yaml', 'config/yaml_config')

MyApplicationVikovan::LoggerManager.initialize_logger(config)

logger = MyApplicationVikovan::LoggerManager.logger

if logger
  logger.info("Application Initialization")
  logger.info("")

  logger.info("Loading libraries...")
  system_libs = ['date', 'time']
  loader.load_libs(system_libs, 'libs')
  logger.info("System libraries loaded: #{system_libs.join(', ')}")
  logger.info("")

  logger.info("Loading configurations...")
  logger.info("Configurations loaded successfully")
  logger.info("")

  logger.info("Displaying configuration data...")
  loader.pretty_print_config_data(config)
  logger.info("")

  logger.info("Logger initialized successfully")
  logger.info("Logger level: #{logger.level}")
  logger.info("")

  logger.info("Testing logging functionality...")
  MyApplicationVikovan::LoggerManager.log_processed_file("Application started successfully")
  MyApplicationVikovan::LoggerManager.log_processed_file("Configuration files loaded")
  MyApplicationVikovan::LoggerManager.log_error("Test error message for verification")
  logger.info("Logging test completed. Check logs/app.log and logs/error.log")
  logger.info("")

  logger.info("Initialization Complete")
else
  puts "Warning: Logger initialization failed. Cannot log to files."
  puts "Please check configuration files."
end

