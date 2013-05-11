require 'devinstall/utils'
require 'devinstall/settings'

module Provider
  module Local
    include Utils

    SETTINGS = {
      local: [:copy, :sudo],
    }

    def provider_init;end
    
    def profider_final;end
    
    def upload_sources(cfg, src, dst)
      config =Devinstall::Settings.instance
      copy_command=config.local[:copy]
      command("#{copy_command} #{src} #{dst}") unless src == dst
    end

    def download_file(cfg, file, local)
      config=Devinstall::Settings.instance
      copy_command=config.local[:copy]
      command("#{copy_command} #{cfg[:target]}/#{file.to_s} #{local}")
    end

    def upload_file(cfg, file, local)
      config=Devinstall::Settings.instance
      copy_command=config.local[:copy]
      command("#{copy_command} #{local}/#{file} #{cfg[:folder]}")
    end

    def exec_command(cfg, command)
      config=Devinstall::Settings.instance
      sudo=config.local[:sudo]
      command("#{sudo} #{command}")
    end

  end #Local
end #Provider

