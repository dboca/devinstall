require 'yaml'
require 'devinstall/deep_symbolize'
#require 'singleton'

class Hash
  include DeepSymbolizable
end

module Devinstall

  class KeyNotDefinedError < RuntimeError; end

  class UnknownKeyError < RuntimeError; end

  class Settings
    #include Singleton
    attr_accessor :pkg, :env, :type
    FILES = []
    SETTINGS = {}

    def initialize (filename=nil, pkg = nil, env = nil, type = nil)
      return if filename.nil? ## This will return an empty 
      load! filename
      self.pkg = pkg ? pkg : defaults(:package)
      self.env = env ? env.to_sym : defaults(:env).to_sym
      self.type = type ? type.to_sym : defaults(:type).to_sym
      if Array === self.pkg
        self.pkg.each do |p|
          raise KeyNotDefinedError, "Package '#{p}' not defined"               unless SETTINGS[:packages].has_key? p.to_sym
          raise KeyNotDefinedError, "Package #{p} type '#{type}' not defined " unless SETTINGS[:packages][p.to_sym].has_key? self.type
        end
      else
        raise KeyNotDefinedError, "Package '#{pkg}' not defined"               unless SETTINGS[:packages].has_key? self.pkg.to_sym
        raise KeyNotDefinedError, "Package #{pkg} type '#{type}' not defined " unless SETTINGS[:packages][self.pkg.to_sym].has_key? self.type
      end
      raise KeyNotDefinedError, "Missing package" unless self.pkg
      raise KeyNotDefinedError, "Missing environment" unless self.env
      raise KeyNotDefinedError, "Missing package type" unless self.type
    rescue KeyNotDefinedError => e
      puts "#{e.message}"
      raise e
    rescue UnknownKeyError => e
      puts "Program error: #{e.message} at:"
      puts e.backtrace
      raise e
    end

    def load!(filename) # Multiple load -> merge settings
      unless File.exist?(filename)
        puts "Unable to find config file \"#{filename}\""
        exit!
      end
      unless FILES.include? filename
        FILES << filename
        newsets = YAML::load_file(filename).deep_symbolize
        deep_merge!(SETTINGS, newsets)
      end
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

    def self.instance(filename=nil, pkg = nil, env = nil, type =nil)
      @@_instance ||=new(filename,pkg,env,type)
    end

    def local(key)
      raise UnknownKeyError, "Don't know what are you asking about: '#{key}'" unless [:folder, :temp].include? key
      ret=SETTINGS[:local][key]
      if SETTINGS[:packages][self.pkg.to_sym][self.type].has_key? :local
        ret = SETTINGS[:packages][self.pgk.to_sym][self.type][:local][key] || ret
      end
      ret or raise KeyNotDefinedError, "Undefined key :local:#{key} or :#{self.pkg}:local:#{key}"
    end

    def build(key)
      raise UnknownKeyError, "Don't know what are you asking about: '#{key}'" unless [:user, :host, :folder, :target, :arch, :command, :provider].include? key
      ret=SETTINGS[:build][key]
      if SETTINGS[:packages][self.pkg.to_sym][self.type].has_key? :build
        ret = SETTINGS[:packages][self.pkg.to_sym][self.type][:build][key] || ret
      end
      ret or raise KeyNotDefinedError, "Undefined key :build:#{key} or :#{self.pkg}:#{self.type}:build:#{key}"
    end

    def install(key)
      raise UnknownKeyError, "Don't know what are you asking about: '#{key}'" unless [:user, :host, :folder, :type, :arch, :provider].include? key
      ret=SETTINGS[:install][self.env][key]
      if SETTINGS[:packages][self.pkg.to_sym][self.type].has_key? :install and SETTINGS[:packages][:install].has_key? self.env
        ret = SETTINGS[:packages][self.pgk.to_sym][self.type][:install][self.env][key] || ret
      end
      ret or raise KeyNotDefinedError, "Undefined key :install:#{self.env.to_s}:#{key} or :#{self.pkg}:install:#{self.env.to_s}:#{key}"
    end

    def tests(key=nil) # tests don't have 'env'
      return SETTINGS.has_key?(:tests) if key.nil?
      raise UnknownKeyError, "Don't know what are you asking about: '#{key}'" unless [:machine, :folder, :user, :command, :provider].include? key
      ret=SETTINGS[:tests][key]
      if SETTINGS[:packages][self.pkg.to_sym][self.type].has_key? :tests
        ret = SETTINGS[:packages][self.pkg.to_sym][self.type][:tests][key] || ret
      end
      ret or raise KeyNotDefinedError, "Undefined key :tests:#{self.env.to_s}:#{key} or :#{self.pkg}:tests:#{self.env.to_s}:#{key}"
    end

    def repos(key)
      raise UnknownKeyError, "Don't know what are you asking about: '#{key}'" unless [:user, :host, :folder, :type, :arch].include? key
      ret=SETTINGS[:repos][self.env][key]
      if SETTINGS[:packages][self.pkg.to_sym][self.type].has_key? :repos and SETTINGS[:packages][:repos].has_key? self.env
        ret = SETTINGS[:packages][self.pkg.to_sym][self.type][:repos][self.env][key] || ret
      end
      ret or raise KeyNotDefinedError, "Undefined key :repos:environments:#{self.env.to_s}:#{key} or :#{self.pkg}:repos:#{self.env.to_s}:#{key}"
    end

    %w(repos packages).each do |m|
      define_method(m) do
        SETTINGS[m.to_sym]
      end
    end

  end
end

