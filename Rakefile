# encoding: utf-8

begin
  require 'bundler/setup'
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

require 'rubygems/tasks'
Gem::Tasks.new

begin
  require 'rubocop/rake_task'

  RuboCop::RakeTask.new
rescue LoadError
  task :rubocop do
    abort 'Rubocop is not available.'
  end
end

begin
  require 'yard'

  YARD::Rake::YardocTask.new
rescue LoadError
  task :yard do
    abort 'YARD is not available.'
  end
end

task :doc do
  Rake::Task['yard'].invoke
  YARD::CLI::Stats.run('--list-undoc')
end
