require 'yaml'
require 'devinstall/deep_symbolize'
require 'singleton'
require 'pp'

class Hash
  include DeepSymbolizable
end


module Devinstall

  class KeyNotDefinedError < RuntimeError
  end
  class UnknownKeyError < RuntimeError
  end

  class Settings
    include Singleton

    FILES     = []
    SETTINGS  = {}
    MDEFS     = {
        local:    [:folder, :temp],
        build:    [:folder, :command, :provider, :type, :arch, :target],
        install:  [:folder, :command, :provider, :type, :arch],
        tests:    [:folder, :command, :provider],
        repos:    [:folder, :provider, :type, :arch],
        defaults: [:type, :env]
    }
    PROVIDERS = {}
    class Action
      include Enumerable

      def initialize(m, pkg, type, env)
        @method, @pkg, @type, @env = (m.to_sym rescue m), (pkg.to_sym rescue pkg), (type.to_sym rescue type), (env.to_sym rescue env)
      end

      def has_key?(key)
        Settings.instance.send(@method, key, pkg: @pkg, type: @type, env: @env) rescue false
      end

      def [](key)
        Settings.instance.send(@method, key, pkg: @pkg, type: @type, env: @env)
      end

      def each
        config=Settings.instance
        Settings::MDEFS[@method].each do |key|
          yield(key, config.send(@method, key, pkg: @pkg, type: @type, env: @env)) if block_given?
        end
      end
    end ## Class Action

    def load! (filename)
      if File.exist?(File.expand_path(filename))
        unless FILES.include? filename
          FILES << filename
          data   = YAML::load_file(filename).deep_symbolize
          merger = proc do |_, v1, v2|
            Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2
          end
          SETTINGS.merge! data, &merger
        end
      end
    end

    def method_missing (method, *args)
      raise UnknownKeyError, "Undefined section '#{method}'" unless method_defined? method
      key  = (args.shift or {})
      rest = (Hash === key) ? key : (args.shift or {})
      pkg = rest[:pkg]
      if pkg.nil?
       raise UnknownKeyError, "Unknown key #{key}" unless key_defined? method,key
       return SETTINGS[method][key] rescue raise "#{method}: Package must be defined"
      end
      type = rest[:type] || defaults(:type)
      env  = rest[:env] || defaults(:env)
      return Action.new(method, pkg, type, env) if Hash === key
      raise UnknownKeyError, "Unknown key #{key}" unless key_defined? method,key
      global_or_local(method, key, pkg, type, env) or
          raise KeyNotDefinedError, "Undefined key '#{method}:#{key}' or alternate for ['#{pkg}' '#{type}' '#{env}']"
    end

    def respond_to_missing?(method, _)
      method_defined? method
    end

    def register_provider(provider, methods)
      PROVIDERS[provider]=methods
    end

    def unregister_provider(provider)
      PROVIDERS.delete(provider)
    end

    private

    def key_chain(*keys)
      res=SETTINGS
      keys.each do |key|
        next if key.nil?
        return nil unless res.has_key? key.to_sym
        res=res[key.to_sym]
      end
      res
    end

    def global_or_local(section, key, pkg, type, env)
      key_chain(:packages, pkg, type, section, env, key) ||
          key_chain(:packages, pkg, type, section, key) ||
          key_chain(section, env, key) ||
          key_chain(section, key)
    end

    def key_defined?(method, key)
      method, key = (method.to_sym rescue method), (key.to_sym rescue key)
      method_defined? method and
      (MDEFS[method].include? key rescue false) or
          PROVIDERS.inject(false){|res,(_,v)| res or (v[method].include? key rescue false)}
    end

    def method_defined?(method)
      method = (method.to_sym rescue method)
      (MDEFS.has_key?(method) or
          PROVIDERS.inject(false){|res,(k,_)| res or PROVIDERS[k].has_key? method}) and
          SETTINGS.has_key? method
    end

  end
end

