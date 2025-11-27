# frozen_string_literal: true

require 'rake'

Dir.glob('lib/tasks/*.rake').each { |r| import r }

task default: :help

desc 'Show list of available tasks'
task :help do
  puts 'Available Rake tasks:'
  puts '  rake task1:run  - Run first task'
  puts '  rake task2:run  - Run second task'
  puts '  rake help       - Show this help'
end

