require 'devinstall'
require 'getopt/long'
require 'devinstall/settings'
module Devinstall
  class Cli

include Utils

    def get_config(fnames)
      fnames.each do |f|
        (@opt['config'] ||= (File.expand_path(f) if File.exist? f)) and break
      end
      @opt['config']
    end

    def initialize(*package)
      begin
        @opt = Getopt::Long.getopts(
            ['--config', '-c', Getopt::REQUIRED],
            ['--type', '-t', Getopt::REQUIRED],
            ['--env', '-e', Getopt::REQUIRED],
            ['--verbose', '-v'],
            ['--dry-run', '-d'],
        )
      rescue
        puts 'Invalid option in command line'
        help
      end
      #verbose and dry-run
      $verbose ||= @opt['verbose']
      $dry ||= @opt['dry-run']
      # get config file
      unless get_config(["./devinstall.yml"])
        exit! 'You must specify the config file'
      end
      # parse config file
      Settings.load!(@opt['config'])
      # complete from default values
      %w"package env type".each { |o| @opt[o] ||= Settings.defaults[o.to_sym] if Settings.defaults[o.to_sym] }
      # verify all informations
      if package # a packege was supplied on commandline
        package.each {|p|  @opt['package'] << p }# this overrides all
      end
      %w"package type env".each do |k|
        unless @opt[k]
          puts "You must specify option '#{k}' either as default or in command line"
          help
        end
      end
      # create package
    end

    def build
      @opt['packages'] do |package|
        pk=Devinstall::Pkg.new(package)
        pk.build(@opt['type'].to_sym)
      end
    end

    def install
      @opt['packages'] do |package|
        pk=Devinstall::Pkg.new(package)
        pk.build(@opt['type'].to_sym)
        pk.install(@opt['env'].to_sym)
      end
    end

    def upload
      @opt['packages'].each do |package|
        pk=Devinstall::Pkg.new(package)
        pk.build(@opt['type'].to_sym)
        pk.run_tests(@opt['env'].to_sym)
        pk.upload(@opt['env'].to_sym)
      end
    end

    def test
      @opt['package'].each do |package|
        pk=Devinstall::Pkg.new(package)
        pk.run_tests(@opt['env'].to_sym)
      end
    end

    def help
      puts 'Usage:'
      puts 'pkg-tool command [package_name ... ] --config|-c <file>  --type|-t <package_type> --env|-e <environment>'
      puts 'where command is one of the: build, install, upload, help, version'
      exit! 0
    end

    def version
      puts "devinstall version #{Devinstall::VERSION}"
      puts "pkg-tool version   #{Devinstall::VERSION}"
      exit! 0
    end

  end
end

