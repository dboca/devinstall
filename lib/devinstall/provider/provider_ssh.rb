require 'devinstall/utils'
module Provider
  module Ssh
    include Devinstall::Utils

    def upload_sources(cfg, src, dst)
      config=Settings.instance

      rsync = config.base(:rsync) # should be config.provider[:ssh][:rsync]

      source="#{src}/"
      dest ="#{cfg[:user]}@#{cfg[:host]}:#{dst}"

      command("#{rsync} #{source} #{dest}")
    rescue NoMethodError
      raise "Program error :#{action}"
    end

    def download_file

    end

    def upload_file

    end

    def exec_command(action, command)

    end
  end
end
