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
      $dry ||= @opt['dry-run']
      # add packages
      if package # a package was supplied on command line
        @opt['package']=[] # reset the package array because commandline have priority
        package.each { |p| @opt['package'] << p } # now this overrides everything
      end
    end

    def build
      # get config file
      unless get_config(["./devinstall.yml"])
        exit! 'You must specify the config file'
      end
      # create package
      if @opt['package'].empty?
        Devinstall::Pkg.new(Devinstall::Settings.new(@opt['config'], nil, @opt['type'])).build
      else
        @opt['package'].each do |package|
          Devinstall::Pkg.new(Devinstall::Settings.new(@opt['config'], package, @opt['env'], @opt['type'])).build
        end
      end
    end

    def install
      # get config file
      unless get_config(["./devinstall.yml"])
        exit! 'You must specify the config file'
      end
      @opt['package'].each do |package|
        config=Devinstall::Settings.new(@opt['config'], package, @opt['env'], @opt['type'])
        pk=Devinstall::Pkg.new(config)
        pk.build
        pk.install
      end
    end

    def upload
      # get config file
      unless get_config(["./devinstall.yml"])
        exit! 'You must specify the config file'
      end
      @opt['package'].each do |package|
        config=Devinstall::Settings.new(@opt['config'], package, @opt['env'], @opt['type'])
        pk=Devinstall::Pkg.new(config)
        pk.build
        pk.run_tests
        pk.upload
      end
    end

    def test
      # get config file
      unless get_config(["./devinstall.yml"])
        exit! 'You must specify the config file'
      end
      @opt['package'].each do |package|
        config=Devinstall::Settings.new(@opt['config'], package, @opt['env'], @opt['type'])
        pk=Devinstall::Pkg.new(config)
        pk.run_tests
      end
    end

    def help
      puts 'Usage:'
      puts 'pkg-tool command [package_name ... ] --config|-c <file>  --type|-t <package_type> --env|-e <environment>'
      puts 'where command is one of the: build, install, upload, help, version'
      exit! ""
    end

    def version
      puts "devinstall version #{Devinstall::VERSION}"
      puts "pkg-tool version   #{Devinstall::VERSION}"
      exit! ""
    end

  end
end

