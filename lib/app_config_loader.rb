# frozen_string_literal: true

require 'yaml'
require 'erb'
require 'json'

class AppConfigLoader
  def config(config_path, yaml_dir, &block)
    default_config = load_default_config(config_path)
    additional_configs = load_config(yaml_dir)
    merged_config = default_config.merge(additional_configs)

    if block_given?
      yield merged_config
    else
      merged_config
    end
  end

  def pretty_print_config_data(data)
    puts JSON.pretty_generate(data)
  end

  def load_libs(system_libs = [], libs_dir = 'libs')
    @loaded_local_libs ||= []

    system_libs.each do |lib|
      begin
        require lib unless $LOADED_FEATURES.any? { |path| path.include?(lib) }
      rescue LoadError => e
        warn "Error loading system library #{lib}: #{e.message}"
      end
    end

    return unless Dir.exist?(libs_dir)

    ruby_files = Dir.glob(File.join(libs_dir, '*.rb'))
    libs_relative_path = File.join('..', libs_dir)

    ruby_files.each do |file_path|
      lib_name = File.basename(file_path, '.rb')
      require_path = File.join(libs_relative_path, lib_name)

      next if @loaded_local_libs.include?(require_path)

      begin
        require_relative require_path
        @loaded_local_libs << require_path
      rescue LoadError, StandardError => e
        warn "Error loading local library #{file_path}: #{e.message}"
      end
    end
  end

  private

  def load_default_config(config_path)
    unless File.exist?(config_path)
      raise "Configuration file not found: #{config_path}"
    end

    file_content = File.read(config_path)
    erb_template = ERB.new(file_content)
    processed_content = erb_template.result(binding)
    YAML.safe_load(processed_content) || {}
  end

  def load_config(yaml_dir)
    unless Dir.exist?(yaml_dir)
      raise "Configuration directory not found: #{yaml_dir}"
    end

    merged_config = {}
    yaml_files = Dir.glob(File.join(yaml_dir, '*.yaml')) + Dir.glob(File.join(yaml_dir, '*.yml'))

    yaml_files.each do |file_path|
      begin
        config_data = YAML.safe_load(File.read(file_path)) || {}
        merged_config.merge!(config_data)
      rescue StandardError => e
        warn "Error loading config file #{file_path}: #{e.message}"
      end
    end

    merged_config
  end
end

