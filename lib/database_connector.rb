# frozen_string_literal: true

require_relative 'my_application_vikovan'
require 'fileutils'

module MyApplicationVikovan
  class DatabaseConnector
    attr_reader :db

    def initialize(config = {})
      LoggerManager.log_processed_file('DatabaseConnector: Initializing') if LoggerManager.logger

      @full_config = config
      @config = config['database_config'] || config[:database_config] || {}
      @db = nil
      @db_type = nil
      @mongo_client = nil

      LoggerManager.log_processed_file('DatabaseConnector: Initialized') if LoggerManager.logger
    end

    def connect_to_database
      LoggerManager.log_processed_file('DatabaseConnector: Starting connection to database') if LoggerManager.logger

      @db_type = (@config['database_type'] || @config[:database_type] || 'sqlite').to_s.downcase

      case @db_type
      when 'sqlite'
        connect_to_sqlite
      when 'mongodb', 'mongo'
        connect_to_mongodb
      else
        message = "DatabaseConnector: Unsupported database type '#{@db_type}'"
        LoggerManager.log_error(message) if LoggerManager.logger
        raise Error, message
      end

      LoggerManager.log_processed_file("DatabaseConnector: Successfully connected to #{@db_type}") if LoggerManager.logger
      @db
    end

    def close_connection
      return unless @db

      LoggerManager.log_processed_file("DatabaseConnector: Closing connection to #{@db_type}") if LoggerManager.logger

      case @db_type
      when 'sqlite'
        @db.close if @db.respond_to?(:close)
        @db = nil
        LoggerManager.log_processed_file('DatabaseConnector: SQLite connection closed') if LoggerManager.logger
      when 'mongodb', 'mongo'
        if @mongo_client
          @mongo_client.close
          @mongo_client = nil
        end
        @db = nil
        LoggerManager.log_processed_file('DatabaseConnector: MongoDB connection closed') if LoggerManager.logger
      end

      @db_type = nil
    rescue StandardError => e
      LoggerManager.log_error("DatabaseConnector: Error while closing connection - #{e.message}") if LoggerManager.logger
      raise
    end

    private

    def connect_to_sqlite
      require 'sqlite3'

      LoggerManager.log_processed_file('DatabaseConnector: Connecting to SQLite') if LoggerManager.logger

      sqlite_config = @config['sqlite_database'] || @config[:sqlite_database] || {}
      db_file = sqlite_config['db_file'] || sqlite_config[:db_file] || 'db/local_database.sqlite'
      timeout_ms = (sqlite_config['timeout'] || sqlite_config[:timeout] || 5000).to_i

      db_dir = File.dirname(db_file)
      FileUtils.mkdir_p(db_dir) unless db_dir == '.' || Dir.exist?(db_dir)

      LoggerManager.log_processed_file("DatabaseConnector: SQLite DB file: #{db_file}") if LoggerManager.logger

      @db = SQLite3::Database.new(db_file, timeout: timeout_ms)
      @db.results_as_hash = true

      LoggerManager.log_processed_file("DatabaseConnector: SQLite connected successfully") if LoggerManager.logger
    rescue LoadError => e
      LoggerManager.log_error("DatabaseConnector: sqlite3 gem is not available - #{e.message}") if LoggerManager.logger
      raise Error, "sqlite3 gem is required for SQLite connection: #{e.message}"
    rescue StandardError => e
      LoggerManager.log_error("DatabaseConnector: Failed to connect to SQLite - #{e.message}") if LoggerManager.logger
      raise
    end

    def connect_to_mongodb
      require 'mongo'

      LoggerManager.log_processed_file('DatabaseConnector: Connecting to MongoDB') if LoggerManager.logger

      mongo_config = @config['mongodb_database'] || @config[:mongodb_database] || {}
      uri = mongo_config['uri'] || mongo_config[:uri] || 'mongodb://localhost:27017'
      db_name = mongo_config['db_name'] || mongo_config[:db_name] || 'my_database'

      Mongo::Logger.logger.level = ::Logger::WARN if defined?(Mongo::Logger)

      @mongo_client = Mongo::Client.new(uri, database: db_name)
      @db = @mongo_client.database

      LoggerManager.log_processed_file("DatabaseConnector: MongoDB connected successfully (uri=#{uri}, db=#{db_name})") if LoggerManager.logger
    rescue LoadError => e
      LoggerManager.log_error("DatabaseConnector: mongo gem is not available - #{e.message}") if LoggerManager.logger
      raise Error, "mongo gem is required for MongoDB connection: #{e.message}"
    rescue StandardError => e
      LoggerManager.log_error("DatabaseConnector: Failed to connect to MongoDB - #{e.message}") if LoggerManager.logger
      raise
    end
  end
end

