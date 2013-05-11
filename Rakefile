require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

task :default => :spec

desc 'Run all examples'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = './spec/spec_helper.rb'
  t.rspec_opts = %w{--colour --format documentation}
end

desc 'Run tests with SimpleCov'
task :coverage do
  require 'coveralls'
  Coveralls.wear!
  require 'simplecov'
  require 'simplecov-gem-adapter'
  SimpleCov.start 'gem'
  Rake::Task[:spec].execute
end

