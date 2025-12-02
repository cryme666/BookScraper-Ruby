# frozen_string_literal: true

require 'dotenv/load'
require_relative 'app_config_loader'
require_relative 'my_application_vikovan'
require_relative 'web_parser'
require_relative 'database_connector'
require_relative 'archive_sender'
require 'fileutils'
require 'zip'

module MyApplicationVikovan
  class Engine
    attr_reader :config, :configurator, :db_connector, :parser

    def initialize(loader = AppConfigLoader.new)
      @loader = loader
      @config = nil
      @configurator = MyApplicationVikovan::Configurator.new
      @db_connector = nil
      @parser = nil
      @cart = nil
    end

    def load_config(default_path = 'config/default_config.yaml', yaml_dir = 'config/yaml_config')
      @config = @loader.config(default_path, yaml_dir)

      if MyApplicationVikovan::LoggerManager.logger
        MyApplicationVikovan::LoggerManager.log_processed_file(
          "Engine: Configuration loaded from #{default_path} and #{yaml_dir}"
        )
      else
        puts "Configuration loaded from #{default_path} and #{yaml_dir}"
      end

      @config
    rescue StandardError => e
      if defined?(MyApplicationVikovan::LoggerManager) && MyApplicationVikovan::LoggerManager.logger
        MyApplicationVikovan::LoggerManager.log_error("Engine: Failed to load configuration - #{e.message}")
      end
      raise
    end

    def run(config_params = {})
      load_config unless @config
      initialize_logging

      apply_config_params(config_params)

      begin
        @db_connector = MyApplicationVikovan::DatabaseConnector.new(@config)
        @db_connector.connect_to_database
        MyApplicationVikovan::LoggerManager.log_processed_file('Engine: Database connected') if logger_available?
      rescue StandardError => e
        MyApplicationVikovan::LoggerManager.log_error("Engine: Failed to connect to database - #{e.message}") if logger_available?
        raise
      end

      archive_path = nil

      begin
        run_methods(@configurator.config)
        archive_path = archive_results
        schedule_archive_sending(archive_path) if archive_path
      ensure
        if @db_connector
          @db_connector.close_connection
          MyApplicationVikovan::LoggerManager.log_processed_file('Engine: Database connection closed') if logger_available?
        end
      end

      archive_path
    end

    def run_methods(config_params)
      MyApplicationVikovan::LoggerManager.log_processed_file(
        "Engine: run_methods with params: #{config_params.inspect}"
      ) if logger_available?

      config_params.each do |key, value|
        next unless value.to_i == 1

        method_name = key.to_s

        unless respond_to?(method_name, true)
          MyApplicationVikovan::LoggerManager.log_error("Engine: Method #{method_name} not found") if logger_available?
          next
        end

        begin
          MyApplicationVikovan::LoggerManager.log_processed_file("Engine: Running method #{method_name}") if logger_available?
          send(method_name)
        rescue StandardError => e
          MyApplicationVikovan::LoggerManager.log_error(
            "Engine: Error while running method #{method_name} - #{e.message}"
          ) if logger_available?
        end
      end
    end

    private

    def logger_available?
      defined?(MyApplicationVikovan::LoggerManager) &&
        MyApplicationVikovan::LoggerManager.logger
    end

    def archive_results
      output_dir = 'output'
      return nil unless Dir.exist?(output_dir)

      timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
      archive_name = "results_#{timestamp}.zip"
      archive_path = File.join(output_dir, archive_name)

      files = Dir[File.join(output_dir, '**', '*')].select { |f| File.file?(f) }
      return nil if files.empty?

      ::Zip::File.open(archive_path, ::Zip::File::CREATE) do |zipfile|
        files.each do |file|
          relative_path = file.sub(%r{\A#{Regexp.escape(output_dir + File::SEPARATOR)}}, '')
          zipfile.add(relative_path, file) unless zipfile.find_entry(relative_path)
        end
      end

      MyApplicationVikovan::LoggerManager.log_processed_file(
        "Engine: Results archived to #{archive_path}"
      ) if logger_available?

      archive_path
    rescue StandardError => e
      MyApplicationVikovan::LoggerManager.log_error(
        "Engine: Failed to create archive - #{e.message}"
      ) if logger_available?
      nil
    end

    def schedule_archive_sending(archive_path)
      return unless archive_path && File.exist?(archive_path)

      email_config = @config['email'] || @config[:email] || {}

      to = email_config['to'] || email_config[:to] || ENV['GMAIL_USER']
      from = email_config['from'] || email_config[:from] || ENV['GMAIL_USER']
      subject = email_config['subject'] || email_config[:subject] || 'Parsing results'
      body = email_config['body'] || email_config[:body] || 'See attached archive'

      options = {
        'to' => to,
        'from' => from,
        'subject' => subject,
        'body' => body,
        'via_options' => email_config['via_options'] || email_config[:via_options] || {}
      }

      MyApplicationVikovan::ArchiveSender.perform_async(archive_path, options)
      MyApplicationVikovan::LoggerManager.log_processed_file(
        "Engine: Archive sending scheduled for #{to}"
      ) if logger_available?
    rescue StandardError => e
      MyApplicationVikovan::LoggerManager.log_error(
        "Engine: Failed to schedule archive sending - #{e.message}"
      ) if logger_available?
    end

    def initialize_logging
      MyApplicationVikovan::LoggerManager.initialize_logger(@config)

      if logger_available?
        MyApplicationVikovan::LoggerManager.log_processed_file('Engine: Logging initialized')
      else
        puts 'Logging initialized'
      end
    end

    def apply_config_params(config_params)
      return if config_params.nil? || config_params.empty?

      symbolized = {}
      config_params.each { |k, v| symbolized[k.to_sym] = v }
      @configurator.configure(symbolized)
    end

    def ensure_cart
      return if @cart

      @cart = if @parser && @parser.item_collection
                @parser.item_collection
              else
                MyApplicationVikovan::Cart.new
              end
    end

    def run_website_parser
      MyApplicationVikovan::LoggerManager.log_processed_file('Engine: Starting website parser') if logger_available?

      @parser = MyApplicationVikovan::WebParser::SimpleWebsiteParser.new(@config)
      success = @parser.start_parse

      if success
        @cart = @parser.item_collection
        MyApplicationVikovan::LoggerManager.log_processed_file(
          "Engine: Website parser finished, items=#{@cart.items.length}"
        ) if logger_available?
      else
        MyApplicationVikovan::LoggerManager.log_error('Engine: Website parser failed') if logger_available?
      end
    end

    def run_save_to_csv
      ensure_cart

      output_dir = 'output'
      FileUtils.mkdir_p(output_dir)
      path = File.join(output_dir, 'data.csv')

      @cart.save_to_csv(path)
      MyApplicationVikovan::LoggerManager.log_processed_file("Engine: Data saved to CSV #{path}") if logger_available?
    end

    def run_save_to_json
      ensure_cart

      output_dir = 'output'
      FileUtils.mkdir_p(output_dir)
      path = File.join(output_dir, 'data.json')

      @cart.save_to_json(path)
      MyApplicationVikovan::LoggerManager.log_processed_file("Engine: Data saved to JSON #{path}") if logger_available?
    end

    def run_save_to_yaml
      ensure_cart

      output_dir = File.join('output', 'yaml')
      FileUtils.mkdir_p(output_dir)

      @cart.save_to_yml(output_dir)
      MyApplicationVikovan::LoggerManager.log_processed_file(
        "Engine: Data saved to YAML directory #{output_dir}"
      ) if logger_available?
    end

    def run_save_to_sqlite
      ensure_cart

      db = @db_connector&.db
      unless db && defined?(SQLite3::Database) && db.is_a?(SQLite3::Database)
        MyApplicationVikovan::LoggerManager.log_error('Engine: SQLite database is not available') if logger_available?
        return
      end

      db.execute <<~SQL
        CREATE TABLE IF NOT EXISTS items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          price REAL,
          description TEXT,
          category TEXT,
          image_path TEXT
        );
      SQL

      @cart.items.each do |item|
        db.execute(
          'INSERT INTO items (name, price, description, category, image_path) VALUES (?, ?, ?, ?, ?)',
          [item.name, item.price, item.description, item.category, item.image_path]
        )
      end

      MyApplicationVikovan::LoggerManager.log_processed_file('Engine: Items saved to SQLite') if logger_available?
    end

    def run_save_to_mongodb
      ensure_cart

      db = @db_connector&.db
      unless db && defined?(Mongo::Database) && db.is_a?(Mongo::Database)
        MyApplicationVikovan::LoggerManager.log_error('Engine: MongoDB database is not available') if logger_available?
        return
      end

      collection = db[:items]
      documents = @cart.items.map do |item|
        {
          name: item.name,
          price: item.price,
          description: item.description,
          category: item.category,
          image_path: item.image_path
        }
      end

      collection.insert_many(documents) unless documents.empty?

      MyApplicationVikovan::LoggerManager.log_processed_file('Engine: Items saved to MongoDB') if logger_available?
    end
  end
end

