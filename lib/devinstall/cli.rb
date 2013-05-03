require 'devinstall/package'
require 'getopt/long'
require 'devinstall/settings'
require 'commander/import'

module Cli

  program :name, 'DevInstall'
  program :version, Devinstall::VERSION
  program :description, 'Poor man builder/installer'

  global_option('--config FILE' 'Configuration file to be used') do |file|
    unless Devinstall::Settings.instance.load! file
      puts "Couldn't find #{file}"
      exit!
    end
  end

  global_option('--verbose', 'Verbose output') { $verbose=true }
  global_option('--dry-run', 'Dry-run; don\'t run commands, just pretend to') { $dry=true }
  global_option('--type STRING', 'Package type (deb, rpm, tgz). Currently only deb')
  global_option('--env STRING', 'Package environment to be built for')

  def load_defaults
    %w(./devinstall.yml ./.devinstall.yml ~/.devinstall).each do |f|
      Devinstall::Settings.instance.load! f and return true
    end
    puts "Couldn't find default config file and no --config option given at command line"
    exit!
  end

  command :build do |c|
    c.action do |args, options|
      config=Devinstall::Settings.instance
      load_defaults unless options.config
      type = options.type ? options.type.to_sym : config.defaults(:type)
      env = options.env ? options.env.to_sym : config.defaults(:env)

      args.each do |p|
        pk=Devinstall::Package.new(p, type, env)
        pk.build
      end
    end
  end

  command :install do |c|
    c.action do |args, options|
      config=Devinstall::Settings.instance
      load_defaults unless options.config
      type = options.type ? options.type.to_sym : config.defaults(:type)
      env = options.env ? options.env.to_sym : config.defaults(:env)

      args.each do |p|
        pk=Devinstall::Package.new(p, type, env)
        pk.build
        pk.install
      end
    end
  end

  command :test do |c|
    c.action do |args, options|
      config=Devinstall::Settings.instance
      load_defaults unless options.config
      type = options.type ? options.type.to_sym : config.defaults(:type)
      env = options.env ? options.env.to_sym : config.defaults(:env)

      args.each do |p|
        pk=Devinstall::Package.new(p, type, env)
        pk.run_tests
      end
    end
  end

  command :upload do |c|
    c.action do |args, options|
      config=Devinstall::Settings.instance
      load_defaults unless options.config
      type = options.type ? options.type.to_sym : config.defaults(:type)
      env = options.env ? options.env.to_sym : config.defaults(:env)

      args.each do |p|
        pk=Devinstall::Package.new(p, type, env)
        pk.build
        pk.run_tests
        pk.upload
      end
    end
  end

end

__END__

