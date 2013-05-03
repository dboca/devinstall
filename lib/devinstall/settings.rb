require 'yaml'
require 'devinstall/deep_symbolize'
require 'singleton'
require 'pp'

class Hash
  include DeepSymbolizable
end



module Devinstall

class KeyNotDefinedError < RuntimeError;end
class UnknownKeyError < RuntimeError;end

  class Settings
    include Singleton

    FILES = []
    SETTINGS = {}
    MDEFS={
        local: [:folder, :temp],
        build: [:user, :host, :folder, :target, :arch, :command, :provider],
        install: [:user, :host, :folder, :type, :arch, :provider],
        tests: [:machine, :folder, :user, :command, :provider],
        repos: [:user, :host, :folder, :type, :arch]
    }

    class Action
      include Enumerable

      def initialize(set, sect, pkg, type, env)
        @set=set
        @sect=sect
        @pkg=pkg
        @type=type
        @env=env
      end

      def valid?
        config = Settings.instance
        return false unless Settings::MDEFS.has_key? @sect
        Settings::MDEFS[@sect].inject (true) do |res, k|
          res and config.respond_to? @sect and config.send(@sect, k, pkg: @pkg, type: @type, env: @env)
        end
      rescue KeyNotDefinedError => e
        puts e.message
        puts e.backtrace if $verbose
        return false
      end

      def [](key)
        Settings.instance.send(@sect, key, pkg: @pkg, type: @type, env: @env)
      end

      def each
        config=Settings.instance
        Settings::MDEFS[@sect].each do |key|
          yield(key, config.send(@sect, key, pkg: @pkg, type: @type, env: @env)) if block_given?
        end
      end
    end  ## Class Action

    def load! (filename)
      if File.exist?(File.expand_path(filename))
        unless FILES.include? filename
          FILES << filename
          data = YAML::load_file(filename).deep_symbolize
          merger = proc do |_, v1, v2|
            Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2
          end
          SETTINGS.merge! data, &merger
        end
      end
    end

    def defaults(key=nil)
      return SETTINGS.has_key? :defaults if key.nil?
      raise UnknownKeyError, "Unknowwn key: '#{key}'" unless [:package, :type, :env, :providers].include? key
      return nil unless key_chain(:defaults, key)
      SETTINGS[:defaults][key].to_sym or raise KeyNotDefinedError, "Undefined key :default:#{key.to_s}"
    end

    def base(key=nil)
      return SETTINGS.has_key? :base if key.nil?
      raise UnknownKeyError, "Unknown key: '#{key}'" unless [:rsync, :ssh, :sudo, :scp].include? key
      return nil unless key_chain(:base, key)
      SETTINGS[:base][key] or raise KeyNotDefinedError, "Undefined key :base:#{key.to_s}"
    end

    def method_missing (m, *args)
      raise UnknownKeyError, "Undefined section '#{m}'" unless MDEFS.has_key? m
      key=(args.shift or {})
      if Hash === key
        pkg = key[:pkg] or raise 'package must be defined'
        type = (key[:type] or defaults(:type))
        env = (key[:env] or defaults(:env))
        return Action.new(SETTINGS, m, pkg, type, env)
      end
      rest=(args.shift or {})
      (pkg = rest[:pkg]) or raise 'package must be defined'
      type = (rest[:type] or defaults(:type))
      env = (rest[:env] or defaults(:env))
      pkg=pkg.to_sym
      raise UnknownKeyError, "Unknown key #{key}" unless MDEFS[m].include? key
      global_or_local(m, key, pkg, type, env) or raise KeyNotDefinedError, "Undefined key '#{m}:#{key}' or alternate for ['#{pkg}' '#{type}' '#{env}']"
    end

    def respond_to_missing?(method, _)
      MDEFS.has_key? method and SETTINGS.has_key? method
    end

    private

    def key_chain(*keys)
      res=SETTINGS
      keys.each do |key|
        next if key.nil?
        return nil unless res.has_key? key
        res=res[key]
      end
      res
    end

    def global_or_local(section, key, pkg, type, env)
      key_chain(:packages, pkg, type, section, env, key) ||
          key_chain(:packages, pkg, type, section, key) ||
          key_chain(section, env, key) ||
          key_chain(section, key)
    end

  end
end

