require File.join(File.dirname(__FILE__), 'lib/sir_handel/app.rb')

unless ENV['RACK_ENV'] == 'production'
  require 'rspec/core/rake_task'
  require 'cucumber/rake/task'

  Cucumber::Rake::Task.new

  task :default => [:cucumber]
end
