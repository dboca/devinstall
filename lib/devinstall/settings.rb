require 'yaml'
require 'devinstall/deep_symbolize'
require 'singleton'
require 'pp'

class Hash
  include DeepSymbolizable
end

module Devinstall

  class KeyNotDefinedError < RuntimeError; end

  class UnknownKeyError < RuntimeError; end

  class Settings
    include Singleton

    attr_accessor :env, :type
    FILES = []
    SETTINGS = {}

    def pkg=(pkg)
      if Array === pkg and pkg.length == 1
        @pkg = pkg[0]
      elsif pkg.class.method_defined? :to_sym
        @pkg = pkg.to_sym
      else
        @pkg = pkg
      end
    end

    def pkg
      @pkg
    end

    def validate
      raise KeyNotDefinedError, "Missing package" unless self.pkg
      raise KeyNotDefinedError, "Missing environment" unless self.env
      raise KeyNotDefinedError, "Missing package type" unless self.type
      if Array === self.pkg
        self.pkg.each do |p|
          raise KeyNotDefinedError, "Package '#{p}' not defined"               unless SETTINGS[:packages].has_key? p.to_sym
          raise KeyNotDefinedError, "Package #{p} type '#{type}' not defined " unless SETTINGS[:packages][p.to_sym].has_key? self.type
        end
      else
        raise KeyNotDefinedError, "Package '#{pkg}' not defined"               unless SETTINGS[:packages].has_key? self.pkg.to_sym
        raise KeyNotDefinedError, "Package #{pkg} type '#{type}' not defined " unless SETTINGS[:packages][self.pkg.to_sym].has_key? self.type
      end
    rescue KeyNotDefinedError => e
      raise e
    rescue UnknownKeyError => e
      puts "Program error: #{e.message} at:"
      puts e.backtrace
      exit!
    end

    def load! (filename) # Multiple load -> merge settings
      unless File.exist?(File.expand_path(filename))
        puts "Unable to find config file \"#{File.expand_path(filename)}\""
        exit!
      end
      unless FILES.include? filename
        FILES << filename
        newsets = YAML::load_file(filename).deep_symbolize
        deep_merge!(SETTINGS, newsets)
      end
      ### initialize type, env from defaults unless already defined
      self.env  ||= defaults(:env).to_sym
      self.type ||= defaults(:type).to_sym
    end

    def deep_merge!(target, data)
      merger = proc do |_, v1, v2|
        Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2
      end
      target.merge! data, &merger
    end

    def self.defaults(key=nil)
      return SETTINGS.has_key? :defaults if key.nil?
      raise UnknownKeyError, "Don't know what are you asking about: '#{key}'" unless [:package, :type, :env, :providers].include? key
      SETTINGS[:defaults][key] or raise KeyNotDefinedError, "Undefined key :default:#{key.to_s}"
    end

    def defaults(key=nil)
      self.class.defaults key
    end

    def self.base(key=nil)
      return SETTINGS.has_key? :base if key.nil?
      raise UnknownKeyError, "Don't know what are you asking about: '#{key}'" unless [:rsync, :ssh, :sudo, :scp].include? key
      SETTINGS[:base][key] or raise KeyNotDefinedError, "Undefined key :base:#{key.to_s}"
    end

    def base(key=nil)
      self.class.base key
    end

    def global_or_local(section, key)
      ret = nil
      if SETTINGS[:packages][self.pkg][self.type].has_key? section
        ret ||= SETTINGS[:packages][self.pkg][self.type][section][self.env][key] if SETTINGS[:packages][self.pkg][self.type][section].has_key? self.env
        ret ||= SETTINGS[:packages][self.pkg][self.type][section][key] # or nil
      end
      ret ||= SETTINGS[section][self.env][key] if SETTINGS[section].has_key? self.env
      ret ||= SETTINGS[section][key] # or nil
      ret
    end

    def local(key=nil)
      return SETTINGS.has_key? :local if key.nil?
      raise UnknownKeyError, "Don't know what are you asking about: '#{key}'" unless [:folder, :temp].include? key
      global_or_local(:local, key) or raise KeyNotDefinedError, "Undefined key :local:#{key} or :#{self.pkg}:local:#{key}"
    end

    def build(key=nil)
      return (SETTINGS.has_key? :build or SETTINGS[:packages][self.pkg][self.type].has_key? :build) if key.nil?
      raise UnknownKeyError, "Don't know what are you asking about: '#{key}'" unless [:user, :host, :folder, :target, :arch, :command, :provider].include? key
      global_or_local(:build, key) or raise KeyNotDefinedError, "Undefined key :build:#{key} or :#{self.pkg}:#{self.type}:build:#{key}"
    end

    def install(key=nil)
      return SETTINGS.has_key? :install if key.nil?
      raise UnknownKeyError, "Don't know what are you asking about: '#{key}'" unless [:user, :host, :folder, :type, :arch, :provider].include? key
      global_or_local(:install, key) or raise KeyNotDefinedError, "Undefined key :install:#{self.env.to_s}:#{key} or :#{self.pkg}:install:#{self.env.to_s}:#{key}"
    end

    def tests(key=nil) # tests don't have 'env'
      return SETTINGS.has_key?(:tests) if key.nil?
      raise UnknownKeyError, "Don't know what are you asking about: '#{key}'" unless [:machine, :folder, :user, :command, :provider].include? key
      global_or_local(:tests, key) or raise KeyNotDefinedError, "Undefined key :tests:#{self.env.to_s}:#{key} or :#{self.pkg}:tests:#{self.env.to_s}:#{key}"
    end

    def repos(key=nil)
      return SETTINGS.has_key?(:repos) if key.nil?
      raise UnknownKeyError, "Don't know what are you asking about: '#{key}'" unless [:user, :host, :folder, :type, :arch].include? key
      global_or_local(:repos, key) or raise KeyNotDefinedError, "Undefined key :repos:environments:#{self.env.to_s}:#{key} or :#{self.pkg}:repos:#{self.env.to_s}:#{key}"
    end

    def packages(key=nil)
      return SETTINGS.has_key?(:packages) if key.nil?
      SETTINGS[:packages][key] ## no checks here!
    end

  end
end

