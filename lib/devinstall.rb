require 'devinstall/version'
require 'devinstall/settings'

module Devinstall
  class Cli
    extend self
    @_package_version=''
    @package_files   =Hash.new('')

    def new (config_file)
      Settings.load!(config_file)
      package          =Settings.base[:package]
      changelog        ="#{Settings.local[:folder]}/#{package}/debian/changelog"
      @_package_version=File.open(changelog, 'r').gets.chomp.sub(/^.*\((.*)\).*$/, "\1")
      pname            ="#{package}_#@_package_version"
      @package_files   ={deb: "#{pname}_all.deb",
                         tgz: "#{pname}.tar.gz",
                         dsc: "#{pname}.dsc",
                         chg: "#{pname}_debian.changes"}
    end

    def copy_to_build_host
      rsync       =Settings.base[:rsync]
      local_folder=Settings.local[:folder]
      build_user  =Settings.build[:user]
      build_host  =Settings.build[:host]
      build_folder=Settings.build[:folder]

      system("#{rsync} -az #{local_folder}/ #{build_user}@#{build_host}:#{build_folder}")
    end

    def build_package
      package     =Settings.base[:package]
      ssh         =Settings.base[:ssh_command]
      build_user  =Settings.build[:user]
      build_host  =Settings.build[:host]
      build_folder=Settings.build[:folder]

      system("#{ssh} #{build_user}@#{build_host} -c \" cd #{build_folder}/#{package} && dpkg-buildpackage\"")
    end
  end
end
