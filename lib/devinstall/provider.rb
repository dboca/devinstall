module Devinstall
  class Provider
    @providers={build: :build, install: :install, upload: :repos, run_tests: :test}

    def initialize(pkg, type, env, action=nil)
      @pkg = pkg
      @type = type
      @env = env
      config=Settings.instance
      caller=caller_locations(1, 1)[0].label.to_sym
      @action = action || @providers[caller] # that's realy stupid!
      provider=config.send(action, :provider, pkg:pkg, type:type, env:env)
      require "devinstall/provider/provider_#{provider}"
      #TODO if don't find the required file then search in a plugins folder
      self.singleton_class.send(:include, Kernel.const_get("Provider").const_get("#{provider.capitalize}"))
    end

    def copy_sources # that's upload sources
      config = Settings.instance
      remote = config.build(pkg: @pkg, type: @type, env: @env)[:folder]
      cfg = config.send(@action, pkg: @pkg, type: @type, env: @env)
      local = File.expand_path config.local(pkg: @pkg, type: @type, env: @env)[:folder]
      upload_sources(cfg, local, remote)
    end

    def get_file(file)

    end

    def put_file(file)

    end

    def do_action
      config = Settings.instance
      cfg=config.send(action ,pkg: @pkg, type: @type, env: @env)
      command = cfg[:command].gsub('%f', build[:folder]).
          gsub('%t', cfg[:target]).
          gsub('%p', @pkg.to_s).
          gsub('%T', @type.to_s)
      exec_command(cfg, command)
    end

  end
end
