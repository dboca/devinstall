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
      # get config file
      get_config(["./devinstall.yml", "~/.devinstall.yml"])
      # add packages
      @opt['package']=[] # reset the package array because commandline have priority
      if package # a package was supplied on command line
        package.each { |p| @opt['package'] << p } # now this overrides everything
      end
      #get default packages
      if !@opt.has_key? "config" or @opt['config'].nil? or @opt['config'].empty?
        exit! "No default config file and no --config option at commandline!"
      end
      if @opt['package'].empty?
        config = Devinstall::Settings.new(@opt['config'], nil, @opt['env'], @opt['type']) # Just for pkg :D
        @opt['package'] = config.pkg # we DO have accessor
      end
    end

    def build
      if @opt['config'].empty?
        exit! 'You must specify the config file'
      end
      # create package
      @opt['package'].each do |package|
        pk=Devinstall::Pkg.new(Devinstall::Settings.new(@opt['config'], package, @opt['env'], @opt['type']))
        pk.build
      end
    end

    def install
      if @opt['config'].empty?
        exit! 'You must specify the config file'
      end
      @opt['package'].each do |package|
        pk=Devinstall::Pkg.new(Devinstall::Settings.new(@opt['config'], package, @opt['env'], @opt['type']))
        pk.build
        pk.install
      end
    end

    def upload
      if @opt['config'].empty?
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
      if @opt['config'].empty?
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

