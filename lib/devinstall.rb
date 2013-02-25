require 'devinstall/version'
require 'devinstall/settings'

module Devinstall
  class Cli

    def get_package_version(type)
      if type == :deb
        # curently implemented only for .deb packages
        deb_changelog          ="#{Settings.local[:folder]}/#{package}/debian/changelog"
        deb_package_version    =File.open(deb_changelog, 'r').gets.chomp.sub(/^.*\((.*)\).*$/, "\1")
        @_package_version[:deb]=deb_package_version
      end
    end

    def new (package)
      # curently implemented only for .deb packages (for .rpma later :D)
      @package             =package
      @_package_version    =HAsh.new # versions for types:
      @package_files       =Hash.new
      pname                ="#{package}_#{get_package_version :deb}"
      @package_files[:deb] ={deb: "#{pname}_all.deb",
                             tgz: "#{pname}.tar.gz",
                             dsc: "#{pname}.dsc",
                             chg: "#{pname}_debian.changes"}
      @build               =Hash.new
      if Settings.build.has_key? :user
        @build[:user] = Settings.build[:user]
      else
        @build[:user]=Settings.base[:user]
      end
      @build[:host]  =Settings.build[:host] if Settings.build.has_key? :folder
      @build[:folder]=Settings.build[:folder] if Settings.build.has_key? :folder
      if Settings.packages[@package.to_sym].has_key? :build
        buildbase= Settings[@package.to_sym][:build]
        [:user, :host, :folder].each do |k|
          @build[k]=buildbase[k] if buildbase.has_hey? k
        end
      end
    end

    def copy_to_build_host
      rsync       =Settings.base[:rsync]
      local_folder=Settings.local[:folder]


      system("#{rsync} -az #{local_folder}/ #{@build[:user]}@#{@build[:host]}:#{@build[:folder]}")
    end

    def build_package(type)
      ssh          =Settings.base[:ssh_command]
      build_command=Settings.packages[@package.to_sym][type][:build_command]

      system("#{ssh} #{@build[:user]}@#{@build[:host]} -c \"#{build_command}\"")
    end
  end
end
