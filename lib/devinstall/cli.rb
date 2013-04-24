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
        puts 'Invalid option at command line'
        help
      end
      #verbose and dry-run
      $verbose ||= @opt['verbose']
      $dry     ||= @opt['dry-run']
      # get config file
      unless get_config(["./devinstall.yml"])
        exit! 'You must specify the config file'
      end
      # add packages
      if package # a package was supplied on command line
        @opt['package']=[] # reset the package array because commandline have priority
        package.each {|p|  @opt['package'] << p }# now this overrides everything
      end
    end

    def build
      # create package
      @opt['package'].each do |package|
        config=Devinstall::Settings.new(opt['config'], package, @opt['env'], @opt['type'])
        pk=Devinstall::Pkg.new(package,config)
        pk.build
      end
    end

    def install
      @opt['package'].each do |package|
        config=Devinstall::Settings.new(opt['config'], package, @opt['env'], @opt['type'])
        pk=Devinstall::Pkg.new(package,config)
        pk.build
        pk.install
      end
    end

    def upload
      @opt['package'].each do |package|
        config=Devinstall::Settings.new(opt['config'], package, @opt['env'], @opt['type'])
        pk=Devinstall::Pkg.new(package,config)
        pk.build
        pk.run_tests
        pk.upload
      end
    end

    def test
      @opt['package'].each do |package|
        config=Devinstall::Settings.new(opt['config'],package, @opt['env'], @opt['type'])
        pk=Devinstall::Pkg.new(package,config)
        pk.run_tests
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

