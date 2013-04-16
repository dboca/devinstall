require 'yaml'

class Hash
  include DeepSymbolizable
end

module Settings

  extend self

  @_settings = {}
  attr_reader :_settings

  def load!(filename, options = {})
    unless File.exist?(filename)
      puts "Unable to find config file \"#{filename}\""
      exit!(1)
    end
    newsets = YAML::load_file(filename).deep_symbolize
    newsets = newsets[options[:env].to_sym] if options[:env] && newsets[options[:env].to_sym]
    deep_merge!(@_settings, newsets)
  end

  def deep_merge!(target, data)
    merger = proc { |_, v1, v2|
      Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
    target.merge! data, &merger
  end

  def defaults
    @_settings[:defaults]
  end

  def base
    @_settings[:base]
  end

  def local
    @_settings[:local]
  end

  def build
    @_settings[:build]
  end

  def install
    @_settings[:install]
  end

  def repos
    @_settings[:repos]
  end

  def packages
    @_settings[:packages]
  end

end

