# frozen_string_literal: true

module ItemContainer
  module ClassMethods
    def class_info
      class_name = name
      version = defined?(MyApplicationVikovan::VERSION) ? MyApplicationVikovan::VERSION : 'N/A'
      {
        class_name: class_name,
        version: version
      }
    end

    def instance_count
      @instance_count ||= 0
    end

    def increment_instance_count
      @instance_count ||= 0
      @instance_count += 1
    end
  end

  module InstanceMethods
    def add_item(item)
      @items ||= []
      @items << item
      if defined?(MyApplicationVikovan::LoggerManager) && MyApplicationVikovan::LoggerManager.logger
        MyApplicationVikovan::LoggerManager.log_processed_file("Cart: Item added - name=#{item.name}, price=#{item.price}")
      end
    end

    def remove_item(item)
      @items ||= []
      removed = @items.delete(item)
      if defined?(MyApplicationVikovan::LoggerManager) && MyApplicationVikovan::LoggerManager.logger
        if removed
          MyApplicationVikovan::LoggerManager.log_processed_file("Cart: Item removed - name=#{item.name}, price=#{item.price}")
        else
          MyApplicationVikovan::LoggerManager.log_processed_file("Cart: Attempted to remove item not found - name=#{item.name}")
        end
      end
      removed
    end

    def delete_items
      @items ||= []
      count = @items.length
      @items.clear
      if defined?(MyApplicationVikovan::LoggerManager) && MyApplicationVikovan::LoggerManager.logger
        MyApplicationVikovan::LoggerManager.log_processed_file("Cart: All items deleted - #{count} items removed")
      end
    end

    def generate_test_items(count = 5)
      @items ||= []
      if defined?(MyApplicationVikovan::LoggerManager) && MyApplicationVikovan::LoggerManager.logger
        MyApplicationVikovan::LoggerManager.log_processed_file("Cart: Generating #{count} test items")
      end
      count.times do
        item = MyApplicationVikovan::Item.generate_fake
        add_item(item)
      end
      if defined?(MyApplicationVikovan::LoggerManager) && MyApplicationVikovan::LoggerManager.logger
        MyApplicationVikovan::LoggerManager.log_processed_file("Cart: Successfully generated #{count} test items")
      end
    end

    def method_missing(method_name, *args, &block)
      if method_name == :show_all_items
        @items ||= []
        @items.each_with_index do |item, index|
          puts "Item #{index + 1}:"
          puts item.info
          puts
        end
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      method_name == :show_all_items || super
    end
  end

  def self.included(class_instance)
    class_instance.extend(ClassMethods)
    class_instance.include(InstanceMethods)

    original_initialize = nil
    if class_instance.instance_methods.include?(:initialize) || class_instance.private_instance_methods.include?(:initialize)
      original_initialize = class_instance.instance_method(:initialize)
    end

    class_instance.define_method(:initialize) do |*args, &block|
      class_instance.increment_instance_count
      if original_initialize
        original_initialize.bind(self).call(*args, &block)
      else
        super(*args, &block)
      end
    end
  end
end

