# frozen_string_literal: true

require 'dotenv/load'
require_relative 'lib/archive_sender'

latest_archive = Dir[File.join('output', 'results_*.zip')].max_by do |file|
  File.mtime(file)
end

if latest_archive.nil?
  puts 'No archive found in output/results_*.zip'
  exit 1
end

to_email = ENV['GMAIL_USER']

if to_email.to_s.empty?
  puts 'ENV[GMAIL_USER] is not set. Please configure .env first.'
  exit 1
end

email_options = {
  'to' => to_email,
  'from' => to_email,
  'subject' => 'Manual archive send test',
  'body' => 'Archive from Engine.run test'
}

puts "Sending #{latest_archive} to #{to_email}..."

begin
  MyApplicationVikovan::ArchiveSender.new.perform(latest_archive, email_options)
  puts 'Email send finished. Check your inbox (and Spam/Promotions).'
rescue StandardError => e
  puts "Error while sending email: #{e.class} - #{e.message}"
  puts e.backtrace.join("\n") if e.backtrace
  exit 1
end




