# frozen_string_literal: true

require 'logger'
require 'fileutils'
require 'faker'

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

  class Item
    include Comparable

    def name
      @name
    end

    def name=(value)
      @name = value
    end

    def price
      @price
    end

    def price=(value)
      @price = value
    end

    def description
      @description
    end

    def description=(value)
      @description = value
    end

    def category
      @category
    end

    def category=(value)
      @category = value
    end

    def image_path
      @image_path
    end

    def image_path=(value)
      @image_path = value
    end

    def initialize(params = {}, &block)
      params = normalize_params(params)
      @name = params[:name] || params['name'] || ''
      @price = params[:price] || params['price'] || 0.0
      @description = params[:description] || params['description'] || ''
      @category = params[:category] || params['category'] || ''
      @image_path = params[:image_path] || params['image_path'] || ''

      yield(self) if block_given?

      log_initialization
    end

    def to_s
      attributes = instance_variables.map do |var|
        key = var.to_s.delete('@').to_sym
        value = instance_variable_get(var)
        "#{key}: #{value}"
      end
      attributes.join(", ")
    end

    def info
      begin
        result = to_s
        LoggerManager.log_processed_file("Item info retrieved: #{@name}") if LoggerManager.logger
        result
      rescue StandardError => e
        LoggerManager.log_error("Error retrieving item info: #{e.message}") if LoggerManager.logger
        raise
      end
    end

    def to_h
      instance_variables.each_with_object({}) do |var, hash|
        key = var.to_s.delete('@').to_sym
        hash[key] = instance_variable_get(var)
      end
    end

    def inspect
      "#<#{self.class.name} #{to_s}>"
    end

    def update(&block)
      yield(self) if block_given?
      log_update
      self
    end

    def self.generate_fake
      new(
        name: Faker::Book.title,
        price: Faker::Commerce.price(range: 10.0..100.0),
        description: Faker::Lorem.paragraph(sentence_count: 3),
        category: Faker::Book.genre,
        image_path: "products/#{Faker::File.dir(segment_count: 1)}/#{Faker::File.file_name(ext: 'jpg')}"
      )
    end

    def <=>(other)
      return nil unless other.is_a?(Item)

      price <=> other.price
    end

    private

    def normalize_params(params)
      return {} unless params.is_a?(Hash)

      params
    end

    def log_initialization
      return unless LoggerManager.logger

      category_display = @category.to_s.empty? ? '(empty)' : @category
      message = "Item initialized: name=#{@name}, price=#{@price}, category=#{category_display}"
      LoggerManager.log_processed_file(message)
    end

    def log_update
      return unless LoggerManager.logger

      category_display = @category.to_s.empty? ? '(empty)' : @category
      message = "Item updated: name=#{@name}, price=#{@price}, category=#{category_display}"
      LoggerManager.log_processed_file(message)
    end
  end
end

