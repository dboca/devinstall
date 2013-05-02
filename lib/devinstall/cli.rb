require 'devinstall'
require 'getopt/long'
require 'devinstall/settings'

module Devinstall
  class Cli

    include Utils

    def get_config(*fnames)
      config=nil
      fnames.each do |f|
        (config ||= (File.expand_path(f) if File.exist? f)) and break
      end
      config
    end

    def initialize(*package)
      begin
        opt = Getopt::Long.getopts(
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
      $verbose ||= opt['verbose']
      $dry ||= opt['dry-run']
      # get config file
      config = Devinstall::Settings.instance # is a singleton so we don't use new here
      cfgfile = get_config("./devinstall.yml", "~/.devinstall.yml", opt['config'])
      exit! 'You must specify the config file' if cfgfile.empty?
      config.load! cfgfile # load cfgfile
      config.env  = opt['env']  || config.env
      config.type = opt['type'] || config.type
      @packages = package
      @packages = config.defaults(:package) if @packages.empty?
      exit! 'You must ask for a package' if @packages.empty?
      config.validate
    rescue KeyNotDefinedError => e
      exit! e.message
    end

    def build
      @packages.each do |package|
        pk=Devinstall::Pkg.new(package)
        pk.build
      end
    end

    def install
      config=Devinstall::Settings.instance
      @packages.each do |package|
        pk=Devinstall::Pkg.new(package)
        pk.build
        pk.install
      end
    end

    def upload
      config=Devinstall::Settings.instance
      @packages.each do |package|
        pk=Devinstall::Pkg.new(package)
        pk.build
        pk.run_tests
        pk.upload
      end
    end

    def test
      config=Devinstall::Settings.instance
      @packages.each do |package|
        pk=Devinstall::Pkg.new(package)
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

