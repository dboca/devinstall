require 'devinstall/version'
require 'devinstall/deep_symbolize'
require 'devinstall/utils'
require 'devinstall/settings'
require 'pp'

module Devinstall
  class UndeffError < RuntimeError;
  end


  class Package
    include Utils

    def load_package_plugin(type)
      #TODO if don't find the required file then search in a plugins folder
      require "devinstall/pkg/pkg_#{type.to_s}"
      self.singleton_class.send(:include, Kernel.const_get("Pkg").const_get("#{type.to_s.capitalize}"))
    end

    def initialize(pkg, type, env)
      @package=pkg
      @type=type
      @env=env
      load_package_plugin(type)
    end

    def upload(pkg=@package, type=@type, env=@env)
      config = Settings.instance
      scp = config.base(:scp)
      repo = config.repos(pkg: pkg, type: type, env: env)
      local = config.local(pkg: pkg, type: type, env: env)
      info = get_info(pkg, type, env)
      info[:to_upload].each do |target|
        puts "Uploading #{target.to_s}\t\t[#{info[:files][target]}] to #{repo[:host]}"
        command("#{scp} #{local[:temp]}/#{info[:files][target]} #{repo[:user]}@#{repo[:host]}:#{repo[:folder]}")
      end
    rescue CommandError => e
      puts e.verbose_message
      exit! ''
    rescue KeyNotDefinedError => e
      puts e.message
      exit! ''
    end

    def build(pkg=@package, type=@type, env=@env)
      config = Settings.instance
      puts "Building package #{pkg} type #{type}"
      build = config.build(pkg: pkg, type: type, env: env)
      local = config.local(pkg: pkg, type: type, env: env)
      raise 'Invaild build configuration' unless build.valid?

      ssh = config.base(:ssh)
      rsync = config.base(:rsync)
      local_folder = File.expand_path local[:folder]
      local_temp = File.expand_path local[:temp]

      build_command = build[:command].gsub('%f', build[:folder]).
          gsub('%t', build[:target]).
          gsub('%p', pkg.to_s).
          gsub('%T', type.to_s)

      info=get_info(pkg, type, env)

      #builder = Provider.new(pkg, type, env)[:build]
      #builder.copy_sources
      #builder.do_action
      upload_sources("#{local_folder}/", "#{build[:user]}@#{build[:host]}:#{build[:folder]}")
      command("#{ssh} #{build[:user]}@#{build[:host]} \"#{build_command}\"")
      info[:files].each do |target, file|
        puts "Receiving target #{target.to_s} for #{file.to_s}"
        command("#{rsync} -az #{build[:user]}@#{build[:host]}:#{build[:target]}/#{file.to_s} #{local_temp}")
        #builder.get_file(file)
      end
    rescue CommandError => e
      puts e.verbose_message
      exit! ''
    rescue KeyNotDefinedError => e
      puts e.message
      exit! ''
    end

    def install(pkg=@package, type=@type, env=@env)
      config=Settings.instance
      puts "Installing #{pkg} in #{env} environment."
      install=config.install(pkg: pkg, type: type, env: env)
      temp =config.local(pkg: pkg, type: type, env: env)[:temp]

      sudo = config.base(:sudo)
      scp = config.base(:scp)
      info = get_info(pkg, type, env)
      install[:host] = [install[:host]] unless Array === install[:host]
      install[:host].each do |host|
        info[:to_install].each do |target|
          command("#{scp} #{temp}/#{info[:files][target]} #{install[:user]}@#{host}:#{install[:folder]}")
          command("#{sudo} #{install[:user]}@#{host} #{install[:command]} #{install[:folder]}/#{info[:files][target]}")
        end
      end
    rescue CommandError => e
      puts e.verbose_message
      exit! ''
    rescue KeyNotDefinedError => e
      puts e.message
      exit! ''
    end

    def run_tests(pkg=@package, type=@type, env=@env)
      config=Settings.instance
      # check if we have the test section in the configuration file
      unless config.respond_to? :tests
        puts 'No test section in the config file.'
        puts 'Skipping tests'
        return
      end
      # for tests we will use almost the same setup as for build
      test = config.tests(pkg: pkg, type: type, env: env)
      local = config.local(pkg: pkg, type: type, env: env)
      build = config.build(pkg: pkg, type: type, env: env)

      ssh = config.base(:ssh)
      # replace "variables" in commands
      command = test[:command].
          gsub('%f', test[:folder]).# %f is the folder where the sources are rsync-ed
          gsub('%t', build[:target]).# %t is the folder where the build places the result
          gsub('%p', pkg.to_s) # %p is the package name
      # take the sources from the local folder
      local_folder = File.expand_path local[:folder]
      # upload them to the test machine
      upload_sources("#{local_folder}/", "#{test[:user]}@#{test[:machine]}:#{test[:folder]}")
      puts 'Running all tests'
      puts 'This will take some time and you have no output'
      command("#{ssh} #{test[:user]}@#{test[:machine]} \"#{command}\"")
    rescue CommandError => e
      puts e.verbose_message
      exit! ''
    rescue KeyNotDefinedError => e
      puts e.message
      exit! ''
    end

    def upload_sources (source, dest)
      config=Settings.instance
      rsync = config.base(:rsync)
      command("#{rsync} -az #{source} #{dest}")
    end
  rescue CommandError => e
    puts e.verbose_message
    exit! ''
  rescue KeyNotDefinedError => e
    puts e.message
    exit! ''
  end

end

