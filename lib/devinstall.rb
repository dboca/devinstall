require 'devinstall/version'
require 'devinstall/deep_symbolize'
require 'devinstall/utils'
require 'devinstall/settings' ##  in near future we will have to abandon Settings
                              # for something more complex because we will need to
                              # define things (repos/install-hosts) for different
                              # environments (dev/qa/prelive/live/prod/backup and so)
require 'pp'

module Devinstall

  class Pkg

    include Utils

    # @param [Symbol] type
    def get_version(type)
      if type == :deb
        begin
          deb_changelog = File.expand_path "#{Settings.local[:folder]}/#{@package}/debian/changelog" # This is the folder that should be checked
          deb_package_version = File.open(deb_changelog, 'r') { |f| f.gets.chomp.sub(/^.*\((.*)\).*$/, '\1') }
          @_package_version[:deb] = deb_package_version

        rescue IOError => e
          puts "IO Error while opening #{deb_changelog}"
          puts "Aborting \n #{e}"
          exit! 1
        end
      end
    end

    # @param [String] package
    def initialize (package)
      # curently implemented only for .deb packages (for .rpm later :D)
      @package = package.to_sym
      @_package_version = Hash.new # versions for types:
      @package_files = Hash.new
      arch = Settings.build[:arch]
      pname = "#{package}_#{get_version :deb}"
      @package_files[:deb] = {deb: "#{pname}_#{arch}.deb",
                              tgz: "#{pname}.tar.gz",
                              dsc: "#{pname}.dsc",
                              chg: "#{pname}_amd64.changes"}
    end

    def upload (env)
      scp = Settings.base[:scp]
      repo = {}
      type = Settings.repos[:environments][env][:type].to_sym
      [:user, :host, :folder].each do |k|
        unless Settings.repos[:environments][env].has_key?(k)
          puts "Unexistent key #{k} in repos:environments:#{env}"
          puts "Aborting"
          exit! 1
        end
        repo[k] = Settings.repos[:environments][env][k]
      end
      @package_files[type].each do |p,f|
        puts "Uploading #{f}\t\t[#{p}] to $#{repo[:host]}"
        command("#{scp} #{Settings.local[:temp]}/#{f} #{repo[:user]}@#{repo[:host]}:#{repo[:folder]}")
      end
    end

    # @param [Symbol] type
    def build (type)
      puts "Building package #{@package} type #{type.to_s}"
      unless Settings.packages[@package].has_key? type
        puts "Package '#{@package}' cannot be built for the required environment"
        puts "undefined build configuration for '#{type.to_s}'"
        exit! 1
      end
      build = {}
      [:user, :host, :folder, :target].each do |k|
        unless Settings.build.has_key? k
          puts "Undefined key 'build:#{k.to_s}:'"
          puts "Aborting!"
          exit! 1
        end
        build[k] = Settings.build[k]
      end

      ssh = Settings.base[:ssh]
      build_command = Settings.packages[@package][type][:build_command]
      rsync = Settings.base[:rsync]
      local_folder = File.expand_path Settings.local[:folder]
      local_temp = File.expand_path Settings.local[:temp]

      build_command = build_command.gsub('%f', build[:folder]).
          gsub('%t', Settings.build[:target]).
          gsub('%p', @package.to_s).
          gsub('%T', type.to_s)

      upload_sources("#{local_folder}/", "#{build[:user]}@#{build[:host]}:#{build[:folder]}")
      command("#{ssh} #{build[:user]}@#{build[:host]} \"#{build_command}\"")
      @package_files[type].each do |p, t|
        puts "Receiving target #{p.to_s} for #{t.to_s}"
        command("#{rsync} -az #{build[:user]}@#{build[:host]}:#{build[:target]}/#{t} #{local_temp}")
      end
    end

    def run_tests(env)
      # for tests we will use aprox the same setup as for build
      test = {}
      [:user, :machine, :command, :folder].each do |k|
        unless Settings.tests[env].has_key? k
          puts("Undefined key 'tests:#{env}:#{k.to_s}:'")
          exit! 1
        end
        test[k] = Settings.tests[env][k]
      end
      ssh = Settings.base[:ssh]

      test[:command] = test[:command].gsub('%f', test[:folder]).
          gsub('%t', Settings.build[:target]).
          gsub('%p', @package.to_s)

      local_folder = File.expand_path Settings.local[:folder] #take the sources from the local folder

      upload_sources("#{local_folder}/", "#{test[:user]}@#{test[:machine]}:#{test[:folder]}") # upload them to the test machine

      puts "Running all tests for the #{env} environment"
      puts "This will take some time and you have no output"
      command("#{ssh} #{test[:user]}@#{test[:machine]} \"#{test[:command]}\"")
    rescue => ee
      puts "Unknown exception during parsing config file"
      puts "Aborting (#{ee})"
      exit! 1
    end

    def install (environment)
      puts "Installing #{@package} in #{environment} environment."
      local_temp = Settings.local[:temp]
      sudo = Settings.base[:sudo]
      scp = Settings.base[:scp]
      type = Settings.install[:environments][environment][:type].to_sym
      install = {}
      [:user, :host, :folder].each do |k|
        unless Settings.install[:environments][environment].has_key? k
          puts "Undefined key 'install:#{environment.to_s}:#{k.to_s}'"
          exit! 1
        end
        install[k] = Settings.install[:environments][environment][k]
      end
      case type
        when :deb
          command("#{scp} #{local_temp}/#{@package_files[type][:deb]} #{install[:user]}@#{install[:host]}:#{install[:folder]}")
          command("#{sudo} #{install[:user]}@#{install[:host]} /usr/bin/dpkg -i #{install[:folder]}/#{@package_files[type][:deb]}")
        else
          puts "unknown package type '#{type.to_s}'"
          exit! 1
      end
    end

    def upload_sources (source, dest)
      rsync = Settings.base[:rsync]
      command("#{rsync} -az #{source} #{dest}")
    end
  end
end


