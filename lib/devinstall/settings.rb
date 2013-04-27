require 'yaml'

class Hash
  include DeepSymbolizable
end

module Devinstall

  class KeyNotDefinedError < RuntimeError; end

  class UnknownKeyError < RuntimeError; end

  class Settings
    include Utils
    attr_accessor :pkg, :env, :type

    def initialize (filename, pkg = nil, env = nil, type = nil)
      @@_files ||= []
      @@_settings ||= {}
      load! filename
      self.pkg = pkg ? pkg : defaults(:package)
      self.env = env ? env.to_sym : defaults(:env).to_sym
      self.type = type ? type.to_sym : defaults(:type).to_sym
      if Array === self.pkg
        self.pkg.each do |p|
          raise KeyNotDefinedError, "Package '#{p}' not defined"               unless @@_settings[:packages].has_key? p.to_sym
          raise KeyNotDefinedError, "Package #{p} type '#{type}' not defined " unless @@_settings[:packages][p.to_sym].has_key? self.type
        end
      else
        raise KeyNotDefinedError, "Package '#{p}' not defined"               unless @@_settings[:packages].has_key? self.pkg.to_sym
        raise KeyNotDefinedError, "Package #{p} type '#{type}' not defined " unless @@_settings[:packages][self.pkg.to_sym].has_key? self.type
      end
      raise KeyNotDefinedError, "Missing package" unless self.pkg
      raise KeyNotDefinedError, "Missing environment" unless self.env
      raise KeyNotDefinedError, "Missing package type" unless self.type
    rescue KeyNotDefinedError => e
      puts "#{e.message}"
      exit! "" #here should be raise
    rescue UnknownKeyError => e
      puts "Program error: #{e.message} at:"
      puts e.backtrace
      exit!
    end

    def load!(filename) # Multiple load -> merge settings
      unless File.exist?(filename)
        puts "Unable to find config file \"#{filename}\""
        exit!
      end
      unless @@_files.include? filename
        @@_files << filename
        newsets = YAML::load_file(filename).deep_symbolize
        deep_merge!(@@_settings, newsets)
      end
    end

    def deep_merge!(target, data)
      merger = proc do |_, v1, v2|
        Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2
      end
      target.merge! data, &merger
    end

    def defaults(key=nil)
      return @@_settings.has_key? :defaults if key.nil?
      raise UnknownKeyError, "Don't know what are you asking about: '#{key}'" unless [:package, :type, :env].include? key
      @@_settings[:defaults][key] or raise KeyNotDefinedError, "Undefined key :default:#{key.to_s}"
    end

    def base(key=nil)
      return @@_settings.has_key? :base if key.nil?
      raise UnknownKeyError, "Don't know what are you asking about: '#{key}'" unless [:rsync, :ssh, :sudo, :scp].include? key
      @@_settings[:base][key] or raise KeyNotDefinedError, "Undefined key :base:#{key.to_s}"
    end

    def local(key)
      raise UnknownKeyError, "Don't know what are you asking about: '#{key}'" unless [:folder, :temp].include? key
      ret=@@_settings[:local][key]
      if @@_settings[:packages][self.pkg.to_sym][self.type].has_key? :local
        ret = @@_settings[:packages][self.pgk.to_sym][self.type][:local][key] || ret
      end
      ret or raise KeyNotDefinedError, "Undefined key :local:#{key} or :#{self.pkg}:local:#{key}"
    end

    def build(key)
      raise UnknownKeyError, "Don't know what are you asking about: '#{key}'" unless [:user, :host, :folder, :target, :arch, :command].include? key
      ret=@@_settings[:build][key]
      if @@_settings[:packages][self.pkg.to_sym][self.type].has_key? :build
        ret = @@_settings[:packages][self.pkg.to_sym][self.type][:build][key] || ret
      end
      ret or raise KeyNotDefinedError, "Undefined key :build:#{key} or :#{self.pkg}:#{self.type}:build:#{key}"
    end

    def install(key)
      raise UnknownKeyError, "Don't know what are you asking about: '#{key}'" unless [:user, :host, :folder, :type, :arch].include? key
      ret=@@_settings[:install][self.env][key]
      if @@_settings[:packages][self.pkg.to_sym][self.type].has_key? :install and @@_settings[:packages][:install].has_key? self.env
        ret = @@_settings[:packages][self.pgk.to_sym][self.type][:install][self.env][key] || ret
      end
      ret or raise KeyNotDefinedError, "Undefined key :install:#{self.env.to_s}:#{key} or :#{self.pkg}:install:#{self.env.to_s}:#{key}"
    end

    def tests(key=nil) # tests don't have 'env'
      return @@_settings.has_key?(:tests) if key.nil?
      raise UnknownKeyError, "Don't know what are you asking about: '#{key}'" unless [:machine, :folder, :user, :command].include? key
      ret=@@_settings[:tests][key]
      if @@_settings[:packages][self.pkg.to_sym][self.type].has_key? :tests
        ret = @@_settings[:packages][self.pkg.to_sym][self.type][:tests][key] || ret
      end
      ret or raise KeyNotDefinedError, "Undefined key :tests:#{self.env.to_s}:#{key} or :#{self.pkg}:tests:#{self.env.to_s}:#{key}"
    end

    def repos(key)
      raise UnknownKeyError, "Don't know what are you asking about: '#{key}'" unless [:user, :host, :folder, :type, :arch].include? key
      ret=@@_settings[:repos][self.env][key]
      if @@_settings[:packages][self.pkg.to_sym][self.type].has_key? :repos and @@_settings[:packages][:repos].has_key? self.env
        ret = @@_settings[:packages][self.pkg.to_sym][self.type][:repos][self.env][key] || ret
      end
      ret or raise KeyNotDefinedError, "Undefined key :repos:environments:#{self.env.to_s}:#{key} or :#{self.pkg}:repos:#{self.env.to_s}:#{key}"
    end

    %w(repos packages).each do |m|
      define_method(m) do
        @@_settings[m.to_sym]
      end
    end

  end
end

