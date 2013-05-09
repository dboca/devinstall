require 'simplecov'
require 'simplecov-gem-adapter'
SimpleCov.start 'gem'

Dir[File.expand_path('../support/**/*_spec.rb', __FILE__)].each { |f| require f }

