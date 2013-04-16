require 'devinstall/version'
require 'devinstall/deep_symbolize'
require 'devinstall/settings' ##  in near future we will have to abandon Settings
                              # for something more complex because we will need to
                              # define things (repos/install-hosts) for different
                              # environments (dev/qa/prelive/live/prod/backup and so)
require 'pp'

module Devinstall


  class Pkg

    # @param [Symbol] type
    def get_version(type)
      if type == :deb
        deb_changelog = File.expand_path "#{Settings.local[:folder]}/#{@package}/debian/changelog" # This is the folder that should be checked
        deb_package_version =File.open(deb_changelog, 'r').gets.chomp.sub(/^.*\((.*)\).*$/, '\1')
        @_package_version[:deb]=deb_package_version
      end
    end

    # @param [String] package
    def initialize (package)
      # curently implemented only for .deb packages (for .rpm later :D)
      @package =package.to_sym
      @_package_version =Hash.new # versions for types:
      @package_files =Hash.new
      arch =Settings.build[:arch]
      pname ="#{package}_#{get_version :deb}"
      @package_files[:deb] ={deb: "#{pname}_#{arch}.deb",
                             tgz: "#{pname}.tar.gz",
                             dsc: "#{pname}.dsc",
                             chg: "#{pname}_amd64.changes"}
    end

    def upload (env)
      unless Settings.repos[:environments][env]
        puts "Undefined environment '#{env}'"
        exit! 1
      end
      scp =Settings.base[:scp]
      repo =Hash.new
      type =Settings.repos[:environments][env][:type].to_sym
      [:user, :host, :folder].each do |k|
        fail("Unexistent key repos:#{env}:#{k}") unless Settings.repos[:environments][env].has_key?(k)
        repo[k]=Settings.repos[:environments][env][k]
      end
      @package_files[type].each do |t,p|
        puts "Uploading target #{t}(#{p}) to #{repo[:user]}@#{repo[:host]}:#{repo[:folder]}"
        system("#{scp} #{Settings.local[:temp]}/#{p} #{repo[:user]}@#{repo[:host]}:#{repo[:folder]}")
      end
    end

    # @param [Symbol] type
    def build (type)
      puts "Building package #{@package} type #{type.to_s}"
      unless Settings.packages[@package].has_key?(type)
        puts("Package '#{@package}' cannot be built for the required env")
        puts("undefined build configuration for '#{type.to_s}'")
        exit! 1
      end
      build =Hash.new
      [:user, :host, :folder, :target].each do |k|
        unless Settings.build.has_key?(k)
          puts("Undefined key 'build:#{k.to_s}:'")
          exit!(1)
        end
        build[k]=Settings.build[k]
      end

      ssh =Settings.base[:ssh]
      build_command=Settings.packages[@package][type][:build_command]
      rsync =Settings.base[:rsync]
      local_folder =File.expand_path Settings.local[:folder]
      local_temp =File.expand_path Settings.local[:temp]

      build_command = build_command.gsub('%f', build[:folder]).
          gsub('%t', Settings.build[:target]).
          gsub('%p', @package.to_s).
          gsub('%T', type.to_s)

      system("#{rsync} -az #{local_folder}/ #{build[:user]}@#{build[:host]}:#{build[:folder]}")
      system("#{ssh} #{build[:user]}@#{build[:host]} \"#{build_command}\"")
      @package_files[type].each do |p,t|
        puts "Receiving target #{p.to_s}(#{t.to_s}) from #{build[:user]}@#{build[:host]}:#{build[:target]}"
        system("#{rsync} -az #{build[:user]}@#{build[:host]}:#{build[:target]}/#{t} #{local_temp}")
      end
    end

    def install (env)
      unless Settings.repos[:environments][env]
        puts "Undefined environment '#{env}'"
        exit! 1
      end
      puts "Installing #{@package} in #{env} environment."
      sudo =Settings.base[:sudo]
      scp =Settings.base[:scp]
      type=Settings.install[:environments][env][:type].to_sym
      local_temp =Settings.local[:temp]
      install=Hash.new
      [:user, :host, :folder].each do |k|
        unless Settings.install[:environments][env].has_key? k
          puts "Undefined key 'install:environments:#{env.to_s}:#{k.to_s}'"
          exit!(1)
        end
        install[k]=Settings.install[:environments][env][k]
      end
      case type
        when :deb
          system("#{scp} #{local_temp}/#{@package_files[type][:deb]} #{install[:user]}@#{install[:host]}/#{install[:folder]}")
          system("#{sudo} #{Settings.build[:user]}@#{Settings.build[:host]} \"dpkg -i #{install[:folder]}/#{@package_files[type][:deb]}\"")
        else
          puts "unknown package type '#{type.to_s}'"
          exit!(1)
      end
    end
  end
end


