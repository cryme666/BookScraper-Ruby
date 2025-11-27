# frozen_string_literal: true

require 'logger'
require 'fileutils'

module MyApplicationVikovan
  VERSION = '1.0.0'.freeze

  class Error < StandardError; end

  class LoggerManager
    class << self
      attr_reader :logger

      def initialize_logger(config_hash)
        logging_config = config_hash['logging'] || config_hash[:logging]
        return unless logging_config

        directory = logging_config['directory'] || logging_config[:directory] || 'logs'
        level = logging_config['level'] || logging_config[:level] || 'DEBUG'
        files = logging_config['files'] || logging_config[:files] || {}

        FileUtils.mkdir_p(directory) unless Dir.exist?(directory)

        log_level = convert_log_level(level)
        application_log_file = File.join(directory, files['application_log'] || files[:application_log] || 'app.log')
        error_log_file = File.join(directory, files['error_log'] || files[:error_log] || 'error.log')

        @logger = Logger.new(application_log_file)
        @logger.level = log_level
        @logger.formatter = proc do |severity, datetime, _progname, msg|
          "#{datetime.strftime('%Y-%m-%d %H:%M:%S')} [#{severity}] #{msg}\n"
        end

        @error_logger = Logger.new(error_log_file)
        @error_logger.level = Logger::ERROR
        @error_logger.formatter = proc do |severity, datetime, _progname, msg|
          "#{datetime.strftime('%Y-%m-%d %H:%M:%S')} [#{severity}] #{msg}\n"
        end
      end

      def log_processed_file(message)
        return unless @logger

        @logger.info(message)
      end

      def log_error(message)
        return unless @error_logger

        @error_logger.error(message)
        @logger&.error(message)
      end

      private

      def convert_log_level(level)
        case level.to_s.upcase
        when 'DEBUG'
          Logger::DEBUG
        when 'INFO'
          Logger::INFO
        when 'WARN'
          Logger::WARN
        when 'ERROR'
          Logger::ERROR
        when 'FATAL'
          Logger::FATAL
        else
          Logger::DEBUG
        end
      end
    end
  end
end

