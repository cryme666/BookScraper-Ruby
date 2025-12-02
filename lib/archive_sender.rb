# frozen_string_literal: true

require 'dotenv/load'
require 'sidekiq'
require 'pony'
require_relative 'my_application_vikovan'

module MyApplicationVikovan
  class ArchiveSender
    include Sidekiq::Worker

    sidekiq_options retry: 3, queue: :default

    def self.prompt_email
      loop do
        print 'Enter email address: '
        email = STDIN.gets.to_s.strip

        if email.empty?
          puts 'Email cannot be empty.'
          next
        end

        if email =~ /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/
          return email
        else
          puts 'Invalid email format. Please try again.'
        end
      end
    end

    def perform(archive_path, email_options = {})
      return unless archive_path && File.exist?(archive_path)

      to = email_options['to'] || email_options[:to]
      from = email_options['from'] || email_options[:from]
      subject = email_options['subject'] || email_options[:subject] || 'Parsing results'
      body = email_options['body'] || email_options[:body] || 'See attached archive'

      via_options = email_options['via_options'] || email_options[:via_options] || default_gmail_via_options

      raise 'Recipient email is required' unless to

      Pony.mail(
        to: to,
        from: from,
        subject: subject,
        body: body,
        attachments: {
          File.basename(archive_path) => File.binread(archive_path)
        },
        via: :smtp,
        via_options: via_options
      )

      if MyApplicationVikovan::LoggerManager.logger
        MyApplicationVikovan::LoggerManager.log_processed_file(
          "ArchiveSender: Archive #{archive_path} sent to #{to}"
        )
      end
    rescue StandardError => e
      if MyApplicationVikovan::LoggerManager.logger
        MyApplicationVikovan::LoggerManager.log_error(
          "ArchiveSender: Failed to send archive - #{e.message}"
        )
      end
      raise
    end

    private

    def default_gmail_via_options
      {
        address: 'smtp.gmail.com',
        port: 587,
        user_name: ENV.fetch('GMAIL_USER', nil),
        password: ENV.fetch('GMAIL_APP_PASSWORD', nil),
        authentication: :plain,
        enable_starttls_auto: true
      }
    end
  end
end


