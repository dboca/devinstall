require 'devinstall/utils'
require 'devinstall/settings'

module Provider
  module Ssh
    include Utils

    SETTINGS = {
        build:   [:user, :host],
        install: [:user, :host],
        tests:   [:user, :host],
        repos:   [:user, :host],
        ssh:     [:ssh, :scp, :rsync, :sudo]
    }

    def upload_sources(cfg, src, dst)
      config =Devinstall::Settings.instance
      rsync  = config.ssh(:rsync)
      source = src[-1]=='/' ? src : "#{src}/"       # source folder(we add / because we are using rsync)
      dest   = "#{cfg[:user]}@#{cfg[:host]}:#{dst}" # cfg should provide user and host
      command("#{rsync} #{source} #{dest}")
    rescue NoMethodError => e
      raise "Program error :#{@action}\n #{e.message}"
    end

    def download_file(cfg, file, local)
      config=Devinstall::Settings.instance
      rsync = config.ssh(:rsync) # should be config.provider[:ssh][:rsync]
      command("#{rsync} -az #{cfg[:user]}@#{cfg[:host]}:#{cfg[:target]}/#{file.to_s} #{local}")
    end

    def upload_file(cfg, file, local)
      config=Devinstall::Settings.instance
      scp   = config.ssh(:scp) # should be config.provider[:ssh][:scp]
      hosts = Array === cfg[:host] ? cfg[:host] : [cfg[:host]]
      hosts.each do |host|
        command("#{scp} #{local}/#{file} #{cfg[:user]}@#{host}:#{cfg[:folder]}")
      end
    end

    def exec_command(cfg, command)
      config=Devinstall::Settings.instance
      ssh   = config.ssh(:ssh) # should be config.provider[:ssh][:scp]
      hosts = Array === cfg[:host] ? cfg[:host] : [cfg[:host]]
      hosts.each do |host|
        command("#{ssh} #{cfg[:user]}@#{host} \"#{command}\"")
      end
    end

  end
end
