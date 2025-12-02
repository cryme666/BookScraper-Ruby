# frozen_string_literal: true

require_relative 'my_application_vikovan'
require 'mechanize'
require 'httparty'
require 'faraday'
require 'nokogiri'
require 'fileutils'
require 'uri'
require 'pathname'
require 'thread'

module MyApplicationVikovan
  module WebParser
    class AgentFactory
      def self.create(agent_type, config = {})
        case agent_type.to_s.downcase
        when 'httparty', 'simple'
          agent = HTTPartyAgent.new(config)
          LoggerManager.log_processed_file("Parser: HTTPartyAgent created") if LoggerManager.logger
          agent
        when 'faraday'
          agent = FaradayAgent.new(config)
          LoggerManager.log_processed_file("Parser: FaradayAgent created") if LoggerManager.logger
          agent
        when 'mechanize', 'medium', 'default'
          agent = MechanizeAgent.new(config)
          LoggerManager.log_processed_file("Parser: MechanizeAgent created") if LoggerManager.logger
          agent
        else
          LoggerManager.log_error("Parser: Unknown agent type '#{agent_type}', using Mechanize") if LoggerManager.logger
          MechanizeAgent.new(config)
        end
      end

      def self.create_by_complexity(complexity, config = {})
        LoggerManager.log_processed_file("Parser: Creating agent for complexity '#{complexity}'") if LoggerManager.logger
        case complexity.to_s.downcase
        when 'simple'
          create('httparty', config)
        when 'medium'
          create('mechanize', config)
        when 'complex'
          create('mechanize', config)
        else
          create('mechanize', config)
        end
      end
    end

    class BaseAgent
      attr_accessor :config

      def initialize(config = {})
        @config = config
      end

      def get(url)
        raise NotImplementedError, "Subclass must implement get method"
      end

      def head(url)
        raise NotImplementedError, "Subclass must implement head method"
      end

      def parse_html(html)
        Nokogiri::HTML(html)
      end

      def download_file(url)
        raise NotImplementedError, "Subclass must implement download_file method"
      end
    end

    class HTTPartyAgent < BaseAgent
      def initialize(config = {})
        super(config)
        @timeout = config['timeout'] || config[:timeout] || 30
        LoggerManager.log_processed_file("Parser: HTTPartyAgent initialized with timeout #{@timeout}") if LoggerManager.logger
      end

      def get(url)
        LoggerManager.log_processed_file("Parser: HTTPartyAgent: Fetching page #{url}") if LoggerManager.logger
        response = HTTParty.get(url, timeout: @timeout, headers: default_headers)
        LoggerManager.log_processed_file("Parser: HTTPartyAgent: Page fetched, status #{response.code}") if LoggerManager.logger
        PageWrapper.new(response.body, response.code)
      end

      def head(url)
        LoggerManager.log_processed_file("Parser: HTTPartyAgent: Checking URL #{url}") if LoggerManager.logger
        response = HTTParty.head(url, timeout: @timeout, headers: default_headers)
        ResponseWrapper.new(response.code)
      end

      def download_file(url)
        LoggerManager.log_processed_file("Parser: HTTPartyAgent: Downloading file #{url}") if LoggerManager.logger
        response = HTTParty.get(url, timeout: @timeout, headers: default_headers)
        if response.code == 200
          LoggerManager.log_processed_file("Parser: HTTPartyAgent: File downloaded successfully, size #{response.body.length} bytes") if LoggerManager.logger
          response.body
        else
          LoggerManager.log_error("Parser: HTTPartyAgent: Failed to download file, status #{response.code}") if LoggerManager.logger
          nil
        end
      end

      private

      def default_headers
        {
          'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
      end
    end

    class FaradayAgent < BaseAgent
      def initialize(config = {})
        super(config)
        @timeout = config['timeout'] || config[:timeout] || 30
        @conn = Faraday.new do |f|
          f.request :url_encoded
          f.adapter Faraday.default_adapter
          f.options.timeout = @timeout
        end
        LoggerManager.log_processed_file("Parser: FaradayAgent initialized with timeout #{@timeout}") if LoggerManager.logger
      end

      def get(url)
        LoggerManager.log_processed_file("Parser: FaradayAgent: Fetching page #{url}") if LoggerManager.logger
        response = @conn.get(url) do |req|
          req.headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        end
        LoggerManager.log_processed_file("Parser: FaradayAgent: Page fetched, status #{response.status}") if LoggerManager.logger
        PageWrapper.new(response.body, response.status)
      end

      def head(url)
        LoggerManager.log_processed_file("Parser: FaradayAgent: Checking URL #{url}") if LoggerManager.logger
        response = @conn.head(url) do |req|
          req.headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        end
        ResponseWrapper.new(response.status)
      end

      def download_file(url)
        LoggerManager.log_processed_file("Parser: FaradayAgent: Downloading file #{url}") if LoggerManager.logger
        response = @conn.get(url) do |req|
          req.headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        end
        if response.status == 200
          LoggerManager.log_processed_file("Parser: FaradayAgent: File downloaded successfully, size #{response.body.length} bytes") if LoggerManager.logger
          response.body
        else
          LoggerManager.log_error("Parser: FaradayAgent: Failed to download file, status #{response.status}") if LoggerManager.logger
          nil
        end
      end
    end

    class MechanizeAgent < BaseAgent
      def initialize(config = {})
        super(config)
        @agent = Mechanize.new
        configure_agent
        LoggerManager.log_processed_file("Parser: MechanizeAgent initialized") if LoggerManager.logger
      end

      def get(url)
        LoggerManager.log_processed_file("Parser: MechanizeAgent: Fetching page #{url}") if LoggerManager.logger
        page = @agent.get(url)
        LoggerManager.log_processed_file("Parser: MechanizeAgent: Page fetched, status #{page.code}") if LoggerManager.logger
        PageWrapper.new(page.body, page.code.to_i, page)
      end

      def head(url)
        LoggerManager.log_processed_file("Parser: MechanizeAgent: Checking URL #{url}") if LoggerManager.logger
        response = @agent.head(url)
        ResponseWrapper.new(response.code.to_i)
      end

      def download_file(url)
        LoggerManager.log_processed_file("Parser: MechanizeAgent: Downloading file #{url}") if LoggerManager.logger
        begin
          file = @agent.get_file(url)
          data = if file.respond_to?(:read)
            file.read
          else
            file
          end
          LoggerManager.log_processed_file("Parser: MechanizeAgent: File downloaded successfully, size #{data.length} bytes") if LoggerManager.logger
          data
        rescue StandardError => e
          LoggerManager.log_error("Parser: MechanizeAgent: Failed to download file - #{e.message}") if LoggerManager.logger
          nil
        end
      end

      private

      def configure_agent
        timeout = @config['timeout'] || @config[:timeout] || 30
        @agent.open_timeout = timeout
        @agent.read_timeout = timeout
        @agent.user_agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        LoggerManager.log_processed_file("Parser: MechanizeAgent configured with timeout #{timeout}") if LoggerManager.logger
      end
    end

    class PageWrapper
      attr_reader :body, :code, :original_page

      def initialize(body, code, original_page = nil)
        @body = body
        @code = code
        @original_page = original_page
        @doc = Nokogiri::HTML(body)
        LoggerManager.log_processed_file("Parser: PageWrapper created, body size #{body.length} bytes, code #{code}") if LoggerManager.logger
      end

      def search(selector)
        @doc.search(selector)
      end

      def at(selector)
        @doc.at(selector)
      end

      def is_a?(klass)
        return true if klass == Mechanize::Page && @original_page.is_a?(Mechanize::Page)
        super
      end
    end

    class ResponseWrapper
      attr_reader :code

      def initialize(code)
        @code = code
      end
    end

    class SimpleWebsiteParser
      attr_accessor :config, :agent, :item_collection, :media_dir

      def initialize(config = {})
        LoggerManager.log_processed_file("Parser: Initializing SimpleWebsiteParser") if LoggerManager.logger
        @config = config['web_scraping'] || config[:web_scraping] || {}
        @item_collection = Cart.new
        @mutex = Mutex.new
        initialize_media_dir(config)
        initialize_agent
        LoggerManager.log_processed_file("Parser: SimpleWebsiteParser initialized successfully") if LoggerManager.logger
      end

      def start_parse
        start_page = @config['start_page'] || @config[:start_page]
        LoggerManager.log_processed_file("Parser: start_parse called for page #{start_page}") if LoggerManager.logger
        
        unless check_url_response(start_page)
          LoggerManager.log_error("Parser: Start page #{start_page} is not accessible") if LoggerManager.logger
          return false
        end

        LoggerManager.log_processed_file("Parser: Starting parse from #{start_page}") if LoggerManager.logger

        begin
          LoggerManager.log_processed_file("Parser: Fetching start page") if LoggerManager.logger
          page = @agent.get(start_page)
          LoggerManager.log_processed_file("Parser: Start page fetched successfully") if LoggerManager.logger
          
          product_links = extract_products_links(page)
          LoggerManager.log_processed_file("Parser: Found #{product_links.length} product links") if LoggerManager.logger

          if product_links.empty?
            LoggerManager.log_error("Parser: No product links found on start page") if LoggerManager.logger
            return false
          end

          parse_products_in_parallel(product_links)

          LoggerManager.log_processed_file("Parser: Parsing completed. Total items: #{@item_collection.items.length}") if LoggerManager.logger
          true
        rescue StandardError => e
          LoggerManager.log_error("Parser: Error during parsing - #{e.message}") if LoggerManager.logger
          LoggerManager.log_error("Parser: Backtrace: #{e.backtrace.join("\n")}") if LoggerManager.logger
          false
        end
      end

      def extract_products_links(page)
        LoggerManager.log_processed_file("Parser: Extracting product links from page") if LoggerManager.logger
        links = []
        selector = @config['product_name_selector'] || @config[:product_name_selector] || 'article.product_pod h3 a'
        LoggerManager.log_processed_file("Parser: Using selector '#{selector}' for product links") if LoggerManager.logger

        page.search(selector).each do |link_element|
          href = link_element['href']
          next unless href

          full_url = build_full_url(href)
          if full_url
            links << full_url
            LoggerManager.log_processed_file("Parser: Found product link: #{full_url}") if LoggerManager.logger
          else
            LoggerManager.log_error("Parser: Failed to build full URL from #{href}") if LoggerManager.logger
          end
        end

        LoggerManager.log_processed_file("Parser: Extracted #{links.length} product links") if LoggerManager.logger
        links
      end

      def parse_product_page(product_link)
        LoggerManager.log_processed_file("Parser: Starting to parse product page: #{product_link}") if LoggerManager.logger
        
        unless check_url_response(product_link)
          LoggerManager.log_error("Parser: Product page #{product_link} is not accessible") if LoggerManager.logger
          return
        end

        begin
          LoggerManager.log_processed_file("Parser: Fetching product page") if LoggerManager.logger
          page = @agent.get(product_link)
          LoggerManager.log_processed_file("Parser: Product page fetched successfully") if LoggerManager.logger
          
          LoggerManager.log_processed_file("Parser: Extracting product data") if LoggerManager.logger
          name = extract_product_name(page)
          LoggerManager.log_processed_file("Parser: Product name extracted: #{name}") if LoggerManager.logger
          
          price = extract_product_price(page)
          LoggerManager.log_processed_file("Parser: Product price extracted: #{price}") if LoggerManager.logger
          
          description = extract_product_description(page)
          LoggerManager.log_processed_file("Parser: Product description extracted, length: #{description.length}") if LoggerManager.logger
          
          image_url = extract_product_image(page)
          LoggerManager.log_processed_file("Parser: Product image URL extracted: #{image_url}") if LoggerManager.logger
          
          category = extract_product_category(page)
          LoggerManager.log_processed_file("Parser: Product category extracted: #{category}") if LoggerManager.logger

          local_image_path = ''
          if image_url && !image_url.empty?
            LoggerManager.log_processed_file("Parser: Starting image download and save") if LoggerManager.logger
            local_image_path = download_and_save_image(image_url, name, category)
          else
            LoggerManager.log_processed_file("Parser: No image URL found, skipping image download") if LoggerManager.logger
          end

          LoggerManager.log_processed_file("Parser: Creating Item object") if LoggerManager.logger
          item = Item.new(
            name: name,
            price: price,
            description: description,
            image_path: local_image_path,
            category: category
          )

          @mutex.synchronize do
            @item_collection.add_item(item)
          end
          LoggerManager.log_processed_file("Parser: Parsed product - #{name}, price: #{price}, category: #{category}") if LoggerManager.logger
        rescue StandardError => e
          LoggerManager.log_error("Parser: Error parsing product page #{product_link} - #{e.message}") if LoggerManager.logger
          LoggerManager.log_error("Parser: Backtrace: #{e.backtrace.join("\n")}") if LoggerManager.logger
        end
      end

      def extract_product_name(product)
        selector = @config['product_name_selector'] || @config[:product_name_selector] || 'article.product_pod h3 a'
        
        if product.is_a?(PageWrapper)
          element = product.at('div.product_main h1') || product.at(selector)
          if element
            name = element.text.strip
            LoggerManager.log_processed_file("Parser: Product name found: #{name}") if LoggerManager.logger
            return name
          end
        end
        
        element = product.at(selector) if product.respond_to?(:at)
        if element
          name = element.text.strip
          LoggerManager.log_processed_file("Parser: Product name found: #{name}") if LoggerManager.logger
          return name
        end
        
        LoggerManager.log_error("Parser: Product name not found using selector '#{selector}'") if LoggerManager.logger
        ''
      end

      def extract_product_price(product)
        selector = @config['product_price_selector'] || @config[:product_price_selector] || 'article.product_pod .price_color'
        
        if product.is_a?(PageWrapper)
          element = product.at('div.product_main p.price_color') || product.at(selector)
          if element
            price_text = element.text.strip
            original_price = price_text.dup
            price_text = price_text.gsub(/[£€$,\s]/, '')
            price = price_text.to_f
            LoggerManager.log_processed_file("Parser: Product price found: #{original_price} -> #{price}") if LoggerManager.logger
            return price
          end
        end
        
        element = product.at(selector) if product.respond_to?(:at)
        if element
          price_text = element.text.strip
          original_price = price_text.dup
          price_text = price_text.gsub(/[£€$,\s]/, '')
          price = price_text.to_f
          LoggerManager.log_processed_file("Parser: Product price found: #{original_price} -> #{price}") if LoggerManager.logger
          return price
        end
        
        LoggerManager.log_error("Parser: Product price not found using selector '#{selector}'") if LoggerManager.logger
        0.0
      end

      def extract_product_description(product)
        selector = @config['product_description_selector'] || @config[:product_description_selector] || '#product_description'
        
        if product.is_a?(PageWrapper)
          element = product.at(selector)
          if element
            description = element.text.strip
            LoggerManager.log_processed_file("Parser: Product description found, length: #{description.length}") if LoggerManager.logger
            return description
          end
        end
        
        element = product.at(selector) if product.respond_to?(:at)
        if element
          description = element.text.strip
          LoggerManager.log_processed_file("Parser: Product description found, length: #{description.length}") if LoggerManager.logger
          return description
        end
        
        LoggerManager.log_error("Parser: Product description not found using selector '#{selector}'") if LoggerManager.logger
        ''
      end

      def extract_product_image(product)
        selector = @config['product_image_selector'] || @config[:product_image_selector] || 'article.product_pod img'
        
        if product.is_a?(PageWrapper)
          element = product.at('div.item.active img') || product.at('div.product_main img') || product.at(selector)
          if element
            src = element['src'] || element['data-src']
            if src
              url = build_full_url(src)
              LoggerManager.log_processed_file("Parser: Product image URL found: #{url}") if LoggerManager.logger
              return url
            end
          end
        end
        
        element = product.at(selector) if product.respond_to?(:at)
        if element
          src = element['src'] || element['data-src']
          if src
            url = build_full_url(src)
            LoggerManager.log_processed_file("Parser: Product image URL found: #{url}") if LoggerManager.logger
            return url
          end
        end
        
        LoggerManager.log_error("Parser: Product image not found using selector '#{selector}'") if LoggerManager.logger
        ''
      end

      def check_url_response(url)
        return false if url.nil? || url.empty?

        retries = @config['max_retries'] || @config[:max_retries] || 3
        LoggerManager.log_processed_file("Parser: Checking URL accessibility: #{url} (max retries: #{retries})") if LoggerManager.logger
        
        retries.times do |attempt|
          begin
            response = @agent.head(url)
            if response.code < 400
              LoggerManager.log_processed_file("Parser: URL #{url} is accessible, status: #{response.code}") if LoggerManager.logger
              return true
            else
              LoggerManager.log_error("Parser: URL #{url} returned status #{response.code}") if LoggerManager.logger
            end
          rescue StandardError => e
            LoggerManager.log_error("Parser: URL check failed for #{url} (attempt #{attempt + 1}/#{retries}) - #{e.message}") if LoggerManager.logger
            sleep(1) if attempt < retries - 1
          end
        end
        
        LoggerManager.log_error("Parser: URL #{url} is not accessible after #{retries} attempts") if LoggerManager.logger
        false
      end

      private

      def parse_products_in_parallel(product_links)
        concurrency = (@config['concurrency'] || @config[:concurrency] || 2).to_i
        concurrency = 1 if concurrency < 1
        delay = @config['delay_between_requests'] || @config[:delay_between_requests] || 1
        delay = delay.to_f

        LoggerManager.log_processed_file("Parser: Starting parallel parsing with concurrency=#{concurrency}") if LoggerManager.logger

        queue = Queue.new
        product_links.each { |link| queue << link }

        threads = Array.new(concurrency) do |index|
          Thread.new do
            worker_id = index + 1
            LoggerManager.log_processed_file("Parser: Worker #{worker_id} started") if LoggerManager.logger

            loop do
              link = nil
              begin
                link = queue.pop(true)
              rescue ThreadError
                break
              end

              begin
                LoggerManager.log_processed_file("Parser: Worker #{worker_id} processing #{link}") if LoggerManager.logger
                parse_product_page(link)
              rescue StandardError => e
                LoggerManager.log_error("Parser: Worker #{worker_id} failed on #{link} - #{e.message}") if LoggerManager.logger
              ensure
                if delay > 0
                  LoggerManager.log_processed_file("Parser: Worker #{worker_id} sleeping for #{delay} seconds") if LoggerManager.logger
                  sleep(delay)
                end
              end
            end

            LoggerManager.log_processed_file("Parser: Worker #{worker_id} finished") if LoggerManager.logger
          end
        end

        threads.each(&:join)
      end

      def initialize_media_dir(config)
        LoggerManager.log_processed_file("Parser: Initializing media directory") if LoggerManager.logger
        default_config = config['default'] || config[:default] || {}
        root_dir = default_config['root_dir'] || default_config[:root_dir] || Dir.pwd
        media_dir_name = @config['media_dir'] || @config[:media_dir] || default_config['media_dir'] || default_config[:media_dir] || 'media'
        
        if Pathname.new(media_dir_name).absolute?
          @media_dir = media_dir_name
        else
          @media_dir = File.join(root_dir, media_dir_name)
        end
        
        LoggerManager.log_processed_file("Parser: Media directory path: #{@media_dir}") if LoggerManager.logger
        
        if Dir.exist?(@media_dir)
          LoggerManager.log_processed_file("Parser: Media directory already exists") if LoggerManager.logger
        else
          FileUtils.mkdir_p(@media_dir)
          LoggerManager.log_processed_file("Parser: Media directory created") if LoggerManager.logger
        end
        
        LoggerManager.log_processed_file("Parser: Media directory initialized: #{@media_dir}") if LoggerManager.logger
      end

      def initialize_agent
        agent_type = @config['agent_type'] || @config[:agent_type]
        complexity = @config['site_complexity'] || @config[:site_complexity]

        LoggerManager.log_processed_file("Parser: Initializing agent (type: #{agent_type || 'none'}, complexity: #{complexity || 'none'})") if LoggerManager.logger

        if agent_type
          @agent = AgentFactory.create(agent_type, @config)
          LoggerManager.log_processed_file("Parser: Using agent type '#{agent_type}'") if LoggerManager.logger
        elsif complexity
          @agent = AgentFactory.create_by_complexity(complexity, @config)
          LoggerManager.log_processed_file("Parser: Using agent for complexity '#{complexity}'") if LoggerManager.logger
        else
          @agent = AgentFactory.create('mechanize', @config)
          LoggerManager.log_processed_file("Parser: Using default agent (Mechanize)") if LoggerManager.logger
        end
      end

      def build_full_url(path)
        return nil if path.nil? || path.empty?
        
        base_url = @config['base_url'] || @config[:base_url] || ''
        
        if path.start_with?('http://') || path.start_with?('https://')
          LoggerManager.log_processed_file("Parser: Path is already full URL: #{path}") if LoggerManager.logger
          return path
        end
        
        if path.start_with?('/')
          full_url = "#{base_url}#{path}"
          LoggerManager.log_processed_file("Parser: Built full URL from absolute path: #{full_url}") if LoggerManager.logger
          return full_url
        end
        
        if path.start_with?('../')
          full_url = "#{base_url}/#{path.gsub('../', '')}"
          LoggerManager.log_processed_file("Parser: Built full URL from relative path: #{full_url}") if LoggerManager.logger
          return full_url
        end
        
        full_url = "#{base_url}/#{path}"
        LoggerManager.log_processed_file("Parser: Built full URL: #{full_url}") if LoggerManager.logger
        full_url
      end

      def extract_product_category(product)
        return '' unless product.is_a?(PageWrapper)

        breadcrumb_items = product.search('ul.breadcrumb li')

        if breadcrumb_items && breadcrumb_items.size >= 2
          category_node = breadcrumb_items[-2]
          category = category_node.text.strip

          if category && !category.empty?
            LoggerManager.log_processed_file("Parser: Product category found: #{category}") if LoggerManager.logger
            return category
          end
        end

        LoggerManager.log_error("Parser: Product category not found in breadcrumb") if LoggerManager.logger
        ''
      end

      def download_and_save_image(image_url, product_name, category)
        return '' if image_url.nil? || image_url.empty?

        LoggerManager.log_processed_file("Parser: Starting image download: #{image_url}") if LoggerManager.logger

        begin
          category_dir = sanitize_filename(category.empty? ? 'uncategorized' : category)
          LoggerManager.log_processed_file("Parser: Category directory name: #{category_dir}") if LoggerManager.logger
          
          category_path = File.join(@media_dir, category_dir)
          
          if Dir.exist?(category_path)
            LoggerManager.log_processed_file("Parser: Category directory already exists: #{category_path}") if LoggerManager.logger
          else
            FileUtils.mkdir_p(category_path)
            LoggerManager.log_processed_file("Parser: Category directory created: #{category_path}") if LoggerManager.logger
          end

          file_extension = get_file_extension(image_url)
          LoggerManager.log_processed_file("Parser: File extension determined: #{file_extension}") if LoggerManager.logger
          
          filename = sanitize_filename(product_name) + file_extension
          file_path = File.join(category_path, filename)
          LoggerManager.log_processed_file("Parser: Target file path: #{file_path}") if LoggerManager.logger

          if File.exist?(file_path)
            LoggerManager.log_processed_file("Parser: File already exists, generating unique name") if LoggerManager.logger
            counter = 1
            base_name = sanitize_filename(product_name)
            loop do
              new_filename = "#{base_name}_#{counter}#{file_extension}"
              file_path = File.join(category_path, new_filename)
              break unless File.exist?(file_path)
              counter += 1
            end
            LoggerManager.log_processed_file("Parser: Unique filename generated: #{File.basename(file_path)}") if LoggerManager.logger
          end

          LoggerManager.log_processed_file("Parser: Downloading image file") if LoggerManager.logger
          image_data = @agent.download_file(image_url)
          
          if image_data
            LoggerManager.log_processed_file("Parser: Image downloaded, size: #{image_data.length} bytes") if LoggerManager.logger
            File.binwrite(file_path, image_data)
            relative_path = File.join(category_dir, File.basename(file_path))
            LoggerManager.log_processed_file("Parser: Image saved - #{relative_path}") if LoggerManager.logger
            return relative_path
          else
            LoggerManager.log_error("Parser: Failed to download image from #{image_url}") if LoggerManager.logger
            return ''
          end
        rescue StandardError => e
          LoggerManager.log_error("Parser: Error saving image from #{image_url} - #{e.message}") if LoggerManager.logger
          LoggerManager.log_error("Parser: Backtrace: #{e.backtrace.join("\n")}") if LoggerManager.logger
          return ''
        end
      end

      def sanitize_filename(filename)
        return 'unnamed' if filename.nil? || filename.empty?

        sanitized = filename.gsub(/[^\w\s-]/, '').gsub(/\s+/, '_')
        sanitized = sanitized[0..100]
        sanitized = 'unnamed' if sanitized.empty?
        LoggerManager.log_processed_file("Parser: Filename sanitized: '#{filename}' -> '#{sanitized}'") if LoggerManager.logger
        sanitized
      end

      def get_file_extension(url)
        begin
          uri = URI.parse(url)
          path = uri.path
          ext = File.extname(path)
          ext = '.jpg' if ext.empty?
          ext = ext.downcase
          LoggerManager.log_processed_file("Parser: File extension extracted: #{ext} from #{url}") if LoggerManager.logger
          ext
        rescue StandardError => e
          LoggerManager.log_error("Parser: Error extracting file extension from #{url} - #{e.message}") if LoggerManager.logger
          '.jpg'
        end
      end
    end
  end
end
