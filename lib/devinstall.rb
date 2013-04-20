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
      case type
        when :deb
          begin
            deb_changelog = File.expand_path "#{Settings.local[:folder]}/#{@package}/debian/changelog" # This is the folder that should be checked
            unless File.exists? deb_changelog
              exit! <<-eos
                No 'debian/changelog' found in specified :local:folder (#{Settings.local[:folder]})
                Please check your config file
              eos
            end
            @_package_version[:deb] = File.open(deb_changelog, 'r') { |f| f.gets.chomp.sub(/^.*\((.*)\).*$/, '\1') }
          rescue IOError => e
            exit! <<-eos
              IO Error while opening #{deb_changelog}
              Aborting \n #{e}
            eos
          end
      end
    end

    # @param [String] package
    def initialize (package)
      # curently implemented only for .deb packages (for .rpm later :D)
      unless Settings.packages.has_key? package.to_sym
        exit! "You required an undefined package #{package}"
      end
      @package = package.to_sym
      @_package_version = Hash.new # versions for types:
      @package_files = Hash.new
      arch = Settings.build[:arch]
      p_name = "#{package}_#{get_version :deb}"
      @package_files[:deb] = {deb: "#{p_name}_#{arch}.deb",
                              tgz: "#{p_name}.tar.gz",
                              dsc: "#{p_name}.dsc",
                              chg: "#{p_name}_amd64.changes"}
    end

    def upload (env)
      scp = Settings.base[:scp]
      repo = {}
      type = Settings.repos[:environments][env][:type].to_sym
      [:user, :host, :folder].each do |k|
        unless Settings.repos[:environments][env].has_key?(k)
          exit! "Undefined key #{k} in repos:environments:#{env}"
        end
        repo[k] = Settings.repos[:environments][env][k]
      end
      @package_files[type].each do |p, f|
        puts "Uploading #{f}\t\t[#{p}] to $#{repo[:host]}"
        command("#{scp} #{Settings.local[:temp]}/#{f} #{repo[:user]}@#{repo[:host]}:#{repo[:folder]}")
      end
    end

    # @param [Symbol] type
    def build (type)
      puts "Building package #{@package} type #{type.to_s}"
      unless Settings.packages[@package].has_key? type
        exit! "Package '#{@package}' cannot be built for the required environment"
      end
      build = {}
      [:user, :host, :folder, :target].each do |k|
        unless Settings.build.has_key? k
          exit! "Undefined key 'build:#{k.to_s}:'"
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
          exit! "Undefined key 'tests:#{env}:#{k.to_s}:'"
        end
        test[k] = Settings.tests[env][k]
      end
      ssh = Settings.base[:ssh]
      # replace "variables" in commands
      test[:command] = test[:command].
        gsub('%f', test[:folder]). # %f is the folder where the sources are rsync-ed
        gsub('%t', Settings.build[:target]). # %t is the folder where the build places the result
        gsub('%p', @package.to_s) # %p is the package name
      #take the sources from the local folder
      local_folder = File.expand_path Settings.local[:folder]
      # upload them to the test machine
      upload_sources("#{local_folder}/", "#{test[:user]}@#{test[:machine]}:#{test[:folder]}")
      puts "Running all tests for the #{env} environment"
      puts 'This will take some time and you have no output'
      command("#{ssh} #{test[:user]}@#{test[:machine]} \"#{test[:command]}\"")
    end

    def install (env)
      puts "Installing #{@package} in #{env} environment."
      local_temp = Settings.local[:temp]
      sudo = Settings.base[:sudo]
      scp = Settings.base[:scp]
      type = Settings.install[:environments][env][:type].to_sym
      install = {}
      [:user, :host, :folder].each do |k|
        unless Settings.install[:environments][env].has_key? k
          exit! "Undefined key 'install:#{env.to_s}:#{k.to_s}'"
        end
        install[k] = Settings.install[:environments][env][k]
      end
      install[:host] = [install[:host]] unless Array === install[:host]
      case type
        when :deb
          install[:host].each do |host|
            command("#{scp} #{local_temp}/#{@package_files[type][:deb]} #{install[:user]}@#{host}:#{install[:folder]}")
            command("#{sudo} #{install[:user]}@#{host} /usr/bin/dpkg -i #{install[:folder]}/#{@package_files[type][:deb]}")
          end
        else
          exit! "unknown package type '#{type.to_s}'"
      end
    end

    def upload_sources (source, dest)
      rsync = Settings.base[:rsync]
      command("#{rsync} -az #{source} #{dest}")
    end
  end

end

