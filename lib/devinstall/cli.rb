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
            %w(--config -c),
            %w(--type -t),
            %w(--env -e),
            %w(--verbose -v),
            %w(--dry-run -d),
        )
      rescue
        puts 'Invalid option at command line'
        help
      end
      #verbose and dry-run
      $verbose ||= opt['verbose']
      $dry ||= opt['dry-run']
      # get config file
      cfgfile = get_config('./devinstall.yml', '~/.devinstall.yml', opt['config'])
      exit! 'You must specify the config file' if cfgfile.empty?
      config = Settings.instance # is a singleton so we don't use new here
      config.load! cfgfile # load cfgfile
      @env = opt['env']   || config.defaults(:env)
      @type = opt['type'] || config.defaults(:type)
      @packages = package || []
      @packages = config.defaults(:package) if @packages.empty?
      exit! 'You should ask for a package' if @packages.empty?
      config.validate
    rescue KeyNotDefinedError => e
      exit! e.message
    end

    def build
      @packages.each do |package|
        pk=Devinstall::Pkg.new(package,@type, @env)
        pk.build
      end
    end

    def install
      @packages.each do |package|
        pk=Devinstall::Pkg.new(package, @type, @env)
        pk.build
        pk.install
      end
    end

    def upload
      @packages.each do |package|
        pk=Devinstall::Pkg.new(package,@type, @env)
        pk.build
        pk.run_tests
        pk.upload
      end
    end

    def test
      @packages.each do |package|
        pk=Devinstall::Pkg.new(package, @type, @env)
        pk.run_tests
      end
    end

    def help
      puts 'Usage:'
      puts 'pkg-tool command [package_name ... ] --config|-c <file>  --type|-t <package_type> --env|-e <environment>'
      puts 'where command is one of the: build, install, upload, help, version'
      exit! ''
    end

    def version
      puts "devinstall version #{Devinstall::VERSION}"
      puts "pkg-tool version   #{Devinstall::VERSION}"
      exit! ''
    end

  end
end

