module Devinstall
  class Provider

    def load_provider_plugin(provider)
      require "devinstall/provider/provider_#{provider}"
      self.singleton_class.send(:include, Kernel.const_get('Provider').const_get("#{provider.capitalize}"))
      provider_settings=Kernel.const_get('Provider').const_get("#{provider.capitalize}")::SETTINGS
    end

    def initialize(pkg, type, env, action=nil)
      providers={build: :build, install: :install, upload: :repos, run_tests: :tests}
      @pkg, @type, @env = (pkg.to_sym rescue pkg), (type.to_sym rescue type), (env.to_sym rescue env)
      @action           = action || providers[caller_locations(1, 1)[0].label.to_sym] # that's realy stupid!
      provider          = Settings.instance.send(action, :provider, pkg: @pkg, type: @type, env: @env)
      provider_settings = load_provider_plugin(provider)
      Settings.instance.register_provider(provider.to_sym, provider_settings)
      provider_init
      ObjectSpace.define_finalizer(self, Proc.new{ 
                                     provider_final
                                     Settings.instance.unregister_provider(provider)})
    end

    def copy_sources # that's upload sources
      config = Settings.instance
      remote = config.send(@action, :folder, pkg: @pkg, type: @type, env: @env)
      local  = File.expand_path config.local(:folder, pkg: @pkg, type: @type, env: @env)
      cfg    = config.send(@action, pkg: @pkg, type: @type, env: @env)
      upload_sources(cfg, local, remote)
    end

    def get_file(file)
      config = Settings.instance
      local  = File.expand_path config.local(:temp, pkg: @pkg, type: @type, env: @env)
      cfg    = config.send(@action, pkg: @pkg, type: @type, env: @env)
      download_file(cfg, file, local)
    end

    def put_file(file)
      config = Settings.instance
      local  = File.expand_path config.local(:temp, pkg: @pkg, type: @type, env: @env)
      cfg    = config.send(@action, pkg: @pkg, type: @type, env: @env)
      upload_file(cfg, file, local)
    end

    def do_action(to=nil)
      config  = Settings.instance
      cfg     =config.send(@action, pkg: @pkg, type: @type, env: @env)
      command = cfg[:command].
          gsub('%f', cfg[:folder]).
          gsub('%p', @pkg.to_s).
          gsub('%T', @type.to_s)
      command = command.gsub('%t', cfg[:target]) if cfg.has_key? :target
      command = command.gsub('%a', to) unless to.nil?

      exec_command(cfg, command)
    end

  end
end
