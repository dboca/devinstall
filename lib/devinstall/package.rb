require 'devinstall/version'
require 'devinstall/deep_symbolize'
require 'devinstall/utils'
require 'devinstall/settings'
require 'devinstall/provider'
require 'pp'

module Devinstall
  class UndeffError < RuntimeError;
  end


  class Package
    include Utils

    #noinspection RubyResolve
    def load_package_plugin(type)
      require "devinstall/package/pkg_#{type.to_s}"
      self.singleton_class.send(:include, Kernel.const_get("Pkg").const_get("#{type.to_s.capitalize}"))
    end

    def initialize(pkg, type, env)
      @package, @type, @env = pkg, type, env
      load_package_plugin(type)
    end

    def upload(pkg=@package, type=@type, env=@env)
      uploader = Provider.new(pkg, type, env, :repos)
      info = get_info(pkg, type, env)
      info[:to_upload].each do |target|
        puts "Uploading #{target.to_s}"
        uploader.put_file(info[:files][target].to_s)
      end
    rescue KeyNotDefinedError => e
      puts e.message
      raise "Error uploading #{pkg}"
    end

    def build(pkg=@package, type=@type, env=@env)
      puts "Building package #{pkg} type #{type}"
      info = get_info(pkg, type, env)
      builder = Provider.new(pkg, type, env, :build)
      builder.copy_sources
      builder.do_action
      info[:files].each do |target, file|
        puts "Receiving target #{target.to_s} for #{file.to_s}"
        builder.get_file(file)
      end
    rescue KeyNotDefinedError => e
      puts e.message
      raise "Error uploading #{pkg}"
    end

    def install(pkg=@package, type=@type, env=@env)
      puts "Installing #{pkg} in #{env} environment."
      installer = Provider.new(pkg, type, env, :install)
      info = get_info(pkg, type, env)
      info[:to_install].each do |target| # upload each file to all targets
        installer.put_file(info[:files][target])
        installer.do_action(info[:files][target])
      end
    rescue KeyNotDefinedError => e
      puts e.message
      raise "Error uploading #{pkg}"
    end

    def run_tests(pkg=@package, type=@type, env=@env)
      config=Settings.instance
      # check if we have the test section in the configuration file
      unless config.respond_to? :tests
        puts 'No test section in the config file.'
        puts 'Skipping tests'
        return
      end
      puts 'Running all tests'
      puts 'This will take some time and you have no output'
      tester = Provider.new(pkg, type, env, :tests)
      tester.copy_sources
      tester.do_action
    rescue KeyNotDefinedError => e
      puts e.message
      raise "Error uploading #{pkg}"
    end

  end
end

