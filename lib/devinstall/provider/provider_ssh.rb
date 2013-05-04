require 'devinstall/utils'
require 'devinstall/settings'

module Provider
  module Ssh
    include Utils

    def upload_sources(cfg, src, dst)
      config=Devinstall::Settings.instance
      rsync = config.base(:rsync) # should be config.provider[:ssh][:rsync]
      source = src[-1]=='/' ? src : "#{src}/" # source folder(we add / because we are using rsync)
      dest = "#{cfg[:user]}@#{cfg[:host]}:#{dst}" # cfg should provide user and host
      command("#{rsync} #{source} #{dest}")
    rescue NoMethodError
      raise "Program error :#{action}"
    end

    def download_file(cfg, file, local)
      config=Devinstall::Settings.instance
      rsync = config.base(:rsync) # should be config.provider[:ssh][:rsync]
      command("#{rsync} -az #{cfg[:user]}@#{cfg[:host]}:#{cfg[:target]}/#{file.to_s} #{local}")
    end

    def upload_file(cfg, file, local)
      config=Devinstall::Settings.instance
      scp = config.base(:scp) # should be config.provider[:ssh][:scp]
      if Array === cfg[:host]
        cfg[:host].each do |host|
          command("#{scp} #{local}/#{file} #{cfg[:user]}@#{host}:#{cfg[:folder]}")
        end
      else
        command("#{scp} #{local}/#{file} #{cfg[:user]}@#{cfg[:host]}:#{cfg[:folder]}")
      end
    end

    def exec_command(cfg, command)
      config=Devinstall::Settings.instance
      ssh = config.base(:ssh) # should be config.provider[:ssh][:scp]
      if Array === cfg[:host]
        cfg[:host].each do |host|
          command("#{ssh} #{cfg[:user]}@#{host} \"#{command}\"")
        end
      else
        command("#{ssh} #{cfg[:user]}@#{cfg[:host]} \"#{command}\"")
      end
    end
  end
end
