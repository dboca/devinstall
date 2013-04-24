require 'yaml'

class Hash
  include DeepSymbolizable
end

module Devinstall

class KeyNotDefinedError < RuntimeError
end

class UnknownKeyError < RuntimeError
end

class Settings
  include "Devinstall/Utils"
  attr_accesor :pkg, :env, :type

  def initialize (filename, pkg = nil, env = nil, type = nil)
    @@_files    ||= []
    @@_settings ||= {}
    load! filename
    self.pkg  = pkg  ? pkg.to_sym  : defaults(:package)
    self.env  = env  ? env.to_sym  : defaults(:env)
    self.type = type ? type.to_sym : defaults(:type)
    raise KeyNotDefinedError, "Package '#{pkg}' not defined" unless @_settings[:packages].has_key? pkg
    raise KeyNotDefinedError, "Package type '#{type}' not defined " unless @_settings[:packages][pkg].has_key? type
    raise KeyNotDefinedError, "Missing package" unless pkg
    raise KeyNotDefinedError, "Missing environment" unless env
    raise KeyNotDefinedError, "Missing package type" unless type
  rescue  KeyNotDefinedError => e
    puts "#{e.message}"
    exit! #here should be raise
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
    unless @@_files.contains?filename
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

  def defaults(key)
    raise UnknownKeyError, "Don't know what are you asking about: '#{key}'" unless [:package, :type, :env].contains? key
    @_settings[:defaults][key].to_sym or raise KeyNotDefinedException, "Undefined key :default:#{key.to_s}"
  end

  def base(key)
    raise UnknownKeyError, "Don't know what are you asking about: '#{key}'" unless [:rsync, :ssh, :sudo, :scp].contains? key
    @_settings[:base][key] or raise KeyNotDefinedException, "Undefined key :base:#{key.to_s}"
  end

  def local(key)
    raise UnknownKeyError, "Don't know what are you asking about: '#{key}'" unless [:folder, :temp].contains? key
    ret=@_settings[:local][key]
    if @_settings[:packages].has_key? :local
      ret = @settings[:packages][:local][key] || ret
    end
    ret or raise KeyNotDefinedError, "Undefined key :local:#{key} or :#{self.pkg}:local:#{key}"
  end

  def build(key)
    raise UnknownKeyError, "Don't know what are you asking about: '#{key}'" unless [:user, :host:, :folder, :target, :arch, :command].contains? key
    ret=@_settings[:build][key]
    if @_settings[:packages].has_key? :local
      ret = @settings[:packages][self.type][:build][key] || ret
    end
    ret or raise KeyNotDefinedError, "Undefined key :build:#{key} or :#{self.pkg}:build:#{key}"
  end

  def install(key)
    raise UnknownKeyError, "Don't know what are you asking about: '#{key}'" unless [:user, :host:, :folder, :type, :arch].contains? key
    ret=@_settings[:install][self.env][key]
    if @_settings[:packages].has_key? :install and @_settings[:packages][:install].has_key? self.env
      ret = @settings[:packages][:install][self.env][key] || ret
    end
    ret or raise KeyNotDefinedError, "Undefined key :install:#{self.env.to_s}:#{key} or :#{self.pkg}:install:#{self.env.to_s}:#{key}"
  end

  def tests(key) # tests don't have 'env'
    raise UnknownKeyError, "Don't know what are you asking about: '#{key}'" unless [:machine, :folder, :user, :command].contains? key
    ret=@_settings[:tests][key]
    if @_settings[:packages].has_key? :tests
      ret = @settings[:packages][:tests][key] || ret
    end
    ret or raise KeyNotDefinedError, "Undefined key :tests:#{self.env.to_s}:#{key} or :#{self.pkg}:tests:#{self.env.to_s}:#{key}"
  end

  def repos(key)
    raise UnknownKeyError, "Don't know what are you asking about: '#{key}'" unless [:user, :host:, :folder, :type, :arch].contains? key
    ret=@_settings[:repos][self.env][key]
    if @_settings[:packages].has_key? :repos and @_settings[:packages][:repos].has_key? self.env
      ret = @settings[:packages][:repos][self.env][key] || ret
    end
    ret or raise KeyNotDefinedError, "Undefined key :repos:environments:#{self.env.to_s}:#{key} or :#{self.pkg}:repos:#{self.env.to_s}:#{key}"
  end

    %w(repos packages).each do |m|
    define_method(m) do
      @_settings[m.to_sym]
    end
  end

end

