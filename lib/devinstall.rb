require 'devinstall/version'
require 'devinstall/settings' ##  in near future we will have to abandon Settings
                              # for something more complex because we will need to
                              # define things (repos/install-hosts) for different
                              # environments (dev/qa/prelive/live/prod/backup and so)

module Devinstall
  class Pkg

    def get_package_version(type)
      if type == :deb # curently implemented only for .deb packages
        deb_changelog          ="#{Settings.local[:folder]}/#{package}/debian/changelog"
        deb_package_version    =File.open(deb_changelog, 'r').gets.chomp.sub(/^.*\((.*)\).*$/, "\1")
        @_package_version[:deb]=deb_package_version
      end
    end

    def new (package)
      # curently implemented only for .deb packages (for .rpm later :D)
      @package             =package.to_sym
      @_package_version    =Hash.new # versions for types:
      @package_files       =Hash.new
      pname                ="#{package}_#{get_package_version :deb}"
      @package_files[:deb] ={deb: "#{pname}_all.deb",
                             tgz: "#{pname}.tar.gz",
                             dsc: "#{pname}.dsc",
                             chg: "#{pname}_debian.changes"}
    end

    def deploy_to_repo(environment)
      scp  =Settings.base[:scp]
      repo =Hash.new
      type =Settings.repos[environment][:type]
      [:user, :host, :folder].each do |k|
        fail("Unexistent key repos:#{environment}:#{k}") unless Settings.repos[environment].has_key?(k)
        repo[k]=Settings.repos[environment][k]
      end
      build_pacage(type)
      @package_files[type].each do |p|
        system("#{scp} #{Settings.local[:temp]}/#{p} #{repo[:user]}@#{repo[:host]}:#{repo[:folder]}")
      end

    end

    def build_package(type)
      unless Settings.packages[@package].has_key?(type)
        puts("Package '#{@package}' cannot be built for the required environment")
        puts("undefined build configuration for '#{type.to_s}'")
        SystemExit(1)
      end
      build =Hash.new
      [:user, :host, :folder, :target].each do |k|
        unless Settings.build.has_key?(k)
          puts("Undefined key 'build:#{k.to_s}:'")
          SystemExit(1)
        end
        build[k]=Settings.build[k]
      end
      ssh          =Settings.base[:ssh_command]
      build_command=Settings.packages[@package][type][:build_command]
      rsync        =Settings.base[:rsync]
      local_folder =Settings.local[:folder]
      local_temp   =Settings.local[:temp]
      system("#{rsync} -az #{local_folder}/ #{@build[:user]}@#{build[:host]}:#{build[:folder]}")
      system("#{ssh} #{build[:user]}@#{build[:host]} -c \"#{build_command}\"")
      @package_files[type].each do |p|
        system("#{rsync} -az #{build[:user]}@#{build[:host]}/#{build[:target]}/#{p} #{local_temp}")
      end
    end
  end
end
