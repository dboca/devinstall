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
    merger = proc do |_, v1, v2|
      Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2
    end
    target.merge! data, &merger
  end

  %w(defaults tests base local build install repos packages).each do |m|
    define_method m {@_settings[m.to_sym]}
  end

end

