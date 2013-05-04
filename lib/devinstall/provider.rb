module Devinstall
  class Provider
    @providers={build: :build, install: :install, upload: :repos, run_tests: :test}

    def initialize(pkg, type, env, action=nil)
      @pkg, @type, @env = pkg, type, env
      config = Settings.instance
      caller = caller_locations(1, 1)[0].label.to_sym
      @action = action || @providers[caller] # that's realy stupid!
      provider = config.send(action, :provider, pkg: pkg, type: type, env: env)
      require "devinstall/provider/provider_#{provider}"
                                             #TODO if don't find the required file then search in a plugins folder
      self.singleton_class.send(:include, Kernel.const_get("Provider").const_get("#{provider.capitalize}"))
    end

    def copy_sources # that's upload sources
      config = Settings.instance
      remote = config.send(@action, :folder, pkg: @pkg, type: @type, env: @env)
      local = File.expand_path config.local(:folder, pkg: @pkg, type: @type, env: @env)
      cfg = config.send(@action, pkg: @pkg, type: @type, env: @env)
      upload_sources(cfg, local, remote)
    end

    def get_file(file)
      config = Settings.instance
      local = File.expand_path config.local(:temp, pkg: @pkg, type: @type, env: @env)
      cfg = config.send(@action, pkg: @pkg, type: @type, env: @env)
      download_file(cfg, file, local)
    end

    def put_file(file)
      config = Settings.instance
      local = File.expand_path config.local(:temp, pkg: @pkg, type: @type, env: @env)
      cfg = config.send(@action, pkg: @pkg, type: @type, env: @env)
      upload_file(cfg, file, local)
    end

    def do_action
      config = Settings.instance
      cfg=config.send(@action, pkg: @pkg, type: @type, env: @env)
      command = cfg[:command].
          gsub('%f', cfg[:folder]).
          #gsub('%t', cfg[:target]).
          gsub('%p', @pkg.to_s).
          gsub('%T', @type.to_s)
      exec_command(cfg, command)
    end

  end
end
