require 'devinstall'
require 'getopt/long'
require 'devinstall/settings'
module Devinstall
  class Cli
    # extend self
    # make this module a singleton also
    # See why

    def get_config(fnames)
      fnames.each do |f|
        (@opt['config'] ||= (File.expand_path(f) if File.exist? f)) and break
      end
      @opt['config']
    end

    def initialize
      begin
        @opt = Getopt::Long.getopts(
            ['--package', '-p', Getopt::REQUIRED],
            ['--config', '-c', Getopt::REQUIRED],
            ['--type', '-t', Getopt::REQUIRED],
            ['--env', '-e', Getopt::REQUIRED],
        )
      rescue
        puts 'Invalid option in command line'
        help
        exit! 1
      end
      # get config file
      unless get_config(["./devinstall.yml"])
        puts 'You must specify the config file'
        exit! 1 # Exit
      end
      # parse config file
      Settings.load!(@opt['config'])
      # complete from default values
      %w"package env type".each { |o| @opt[o] ||= Settings.defaults[o.to_sym] if Settings.defaults[o.to_sym] }
      # verify all informations
      %w"package type env".each do |k|
        unless @opt[k]
          puts "You must specify option '#{k}' either as default or in command line"
          help
        end
      end
      # create package
      @package=Devinstall::Pkg.new(@opt['package'])
    end

    def version
      puts "devinstall version #{Devinstall::VERSION}"
      puts "pkg-tool version   #{Devinstall::VERSION}"
      exit(0)
    end

    def help
      puts 'Usage:'
      puts 'pkg-install command --config|-c <file> --package|-p <package> --type|-t <package_type> --env|-e <environment>'
      puts 'where command is one of the: build, install, upload, help, version'
      exit! 0
    end

    def build
      @package.build(@opt['type'].to_sym)
    end

    def install
      package.build(@opt['type'].to_sym)
      package.install(@opt['env'].to_sym)
    end

    def upload
      package.build(@opt['type'].to_sym)
      package.run_tests(@opt['env'].to_sym)
      package.upload(@opt['env'].to_sym)
    end

    def test
      package.run_tests(@opt['env'].to_sym)
    end

  end
end
