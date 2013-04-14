require 'devinstall/version'
require 'devinstall/settings' ##  in near future we will have to abandon Settings
                              # for something more complex because we will need to
                              # define things (repos/install-hosts) for different
                              # environments (dev/qa/prelive/live/prod/backup and so)

module Devinstall
  class Pkg


    # @param [Symbol] type
    def get_version(type)
      if type == :deb
        deb_changelog          = "#{Settings.local[:folder]}/debian/changelog" # This is the folder that should be checked
        deb_package_version    =File.open(deb_changelog, 'r').gets.chomp.sub(/^.*\((.*)\).*$/, "\1")
        @_package_version[:deb]=deb_package_version
      end
    end
  end

  def new (package)
    # curently implemented only for .deb packages (for .rpm later :D)
    @package             =package.to_sym
    @_package_version    =Hash.new # versions for types:
    @package_files       =Hash.new
    arch                 =Settings.build[:arch]
    pname                ="#{package}_#{get_version :deb}"
    @package_files[:deb] ={deb: "#{pname}_#{arch}.deb",
                           tgz: "#{pname}.tar.gz",
                           dsc: "#{pname}.dsc",
                           chg: "#{pname}_debian.changes"}
  end

  def upload! (environment)
    scp  =Settings.base[:scp]
    repo =Hash.new
    type =Settings.repos[environment][:type]
    [:user, :host, :folder].each do |k|
      fail("Unexistent key repos:#{environment}:#{k}") unless Settings.repos[environment].has_key?(k)
      repo[k]=Settings.repos[environment][k]
    end
    build(type)
    @package_files[type].each do |p|
      system("#{scp} #{Settings.local[:temp]}/#{p} #{repo[:user]}@#{repo[:host]}:#{repo[:folder]}")
    end
  end

  # @param [Symbol] type
  def build! (type)
    unless Settings.packages[@package].has_key?(type)
      puts("Package '#{@package}' cannot be built for the required environment")
      puts("undefined build configuration for '#{type.to_s}'")
      exit!(1)
    end
    build =Hash.new
    [:user, :host, :folder, :target].each do |k|
      unless Settings.build.has_key?(k)
        puts("Undefined key 'build:#{k.to_s}:'")
        exit!(1)
      end
      build[k]=Settings.build[k]
    end

    ssh          =Settings.base[:ssh]
    build_command=Settings.packages[@package][type][:build_command]
    rsync        =Settings.base[:rsync]
    local_folder =Settings.local[:folder]
    local_temp   =Settings.local[:temp]
    build_command.sub('%f', Settings.build[:folder]).
        sub('%t', Settings.build[:target]).
        sub('%p', @package.to_s).
        sub('%T', type.to_s)

    system("#{rsync} -az #{local_folder}/ #{build[:user]}@#{build[:host]}:#{build[:folder]}")
    system("#{ssh} #{build[:user]}@#{build[:host]} -c \"#{build_command}\"")
    @package_files[type].each do |p|
      system("#{rsync} -az #{build[:user]}@#{build[:host]}/#{build[:target]}/#{p} #{local_temp}")
    end
  end

  def install! (environment)
    sudo       =Settings.base[:sudo]
    scp        =Settings.base[:scp]
    type       =Settings.install[environment][:type]
    local_temp =Settings.local[:temp]
    build!(type)
    install=Hash.new
    [:user, :host, :folder].each do |k|
      unless Settings.install[environment].has_key?(k)
        puts "Undefined key 'install:#{environment.to_s}:#{k.to_s}'"
        exit!(1)
      end
      install[k]=Settings[environment][k]
    end
    case type.to_sym
      when :deb
        system("#{scp} #{local_temp}/#{@package_files[type][:deb]} #{install[:user]}@#{install[:host]}/#{install[:folder]}")
        system("#{sudo} #{build![:user]}@#{build[:host]} \"dpkg -i #{install[:folder]}/#{@package_files[type][:deb]}")
      else
        puts "unknown package type '#{type.to_s}'"
        exit!(1)
    end
  end
end


