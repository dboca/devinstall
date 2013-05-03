require 'devinstall/version'
require 'devinstall/deep_symbolize'
require 'devinstall/utils'
require 'devinstall/settings'
require 'pp'

module Devinstall
  class UndeffError < RuntimeError; end

  class Pkg
    include Utils

    def get_version(pkg, type, env)
      config=Settings.instance
      folder=config.local(:folder, pkg:pkg, type:type, env:env)
      case type
        when :deb
          begin
            deb_changelog = File.expand_path "#{folder}/#{pkg}/debian/changelog"
            unless File.exists? deb_changelog
              exit! <<-eos
                No 'debian/changelog' found in specified :local:folder (#{folder})
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
        else
          raise UndeffError, "TODO package type #{type}"
      end
    end

    # @param [String] package
    def initialize(package, type, env)
      config=Settings.instance #class variable,first thing!
      @type=type
      @env=env
      @package = package 
      @_package_version = {} # versions for types:
      @package_files = {}
      arch = config.build(pkg:package, type:type, env:env)[:arch]
      p_name = "#{@package}_#{get_version(package, type, env)}"
      @package_files[:deb] = {deb: "#{p_name}_#{arch}.deb",
                              tgz: "#{p_name}.tar.gz",
                              dsc: "#{p_name}.dsc",
                              chg: "#{p_name}_amd64.changes"}
    end

    def upload(pkg=@package, type=@type, env=@env)
      config = Settings.instance
      scp = config.base(:scp)
      repo = config.repos(pkg:pkg, type:type, env:env)
      local = config.local(pkg:pkg, type:type, env:env)

      @package_files[type].each do |p, f|
        puts "Uploading #{f}\t\t[#{p}] to #{repo[:host]}"
        command("#{scp} #{local[:temp]}/#{f} #{repo[:user]}@#{repo[:host]}:#{repo[:folder]}")
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
      build = config.build(pkg:pkg, type:type, env:env)
      local = config.local(pkg:pkg, type:type, env:env)
      raise 'Invaild build configuration' unless build.valid?

      ssh   = config.base(:ssh)
      rsync = config.base(:rsync)
      local_folder = File.expand_path local[:folder]
      local_temp   = File.expand_path local[:temp]

      build_command = build[:command].gsub('%f', build[:folder]).
          gsub('%t', build[:target]).
          gsub('%p', pkg.to_s).
          gsub('%T', type.to_s)

      upload_sources("#{local_folder}/", "#{build[:user]}@#{build[:host]}:#{build[:folder]}")
      command("#{ssh} #{build[:user]}@#{build[:host]} \"#{build_command}\"")
      @package_files[type].each do |p, t|
        puts "Receiving target #{p.to_s} for #{t.to_s}"
        command("#{rsync} -az #{build[:user]}@#{build[:host]}:#{build[:target]}/#{t} #{local_temp}")
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
      install=config.install(pkg:pkg, type:type, env:env)
      temp  =config.local(pkg:pkg, type:type, env:env)[:temp]

      sudo = config.base(:sudo)
      scp  = config.base(:scp)

      install[:host] = [install[:host]] unless Array === install[:host]
      case type
        when :deb
          install[:host].each do |host|
            command("#{scp} #{temp}/#{@package_files[type][:deb]} #{install[:user]}@#{host}:#{install[:folder]}")
            command("#{sudo} #{install[:user]}@#{host} /usr/bin/dpkg -i #{install[:folder]}/#{@package_files[type][:deb]}")
          end
        else
          exit! "unknown package type '#{type.to_s}'"
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
      test  = config.tests(pkg:pkg, type:type, env:env)
      local = config.local(pkg:pkg, type:type, env:env)
      build = config.build(pkg:pkg, type:type, env:env)

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

