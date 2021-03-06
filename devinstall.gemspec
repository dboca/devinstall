# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'devinstall/version'

Gem::Specification.new do |spec|
  spec.name          = 'devinstall'
  spec.version       = Devinstall::VERSION
  spec.authors       = ['Dragos Boca']
  spec.email         = %w(dragos.boca@zero-b.ro)
  spec.description   = %q{package builder and installer}
  spec.summary       = %q{Copy the source files to a build host, build the packages and install builded packages}
  spec.homepage      = 'http://github.com/dragosboca/devinstall'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = %w(lib)

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'simplecov-gem-adapter'
  spec.add_development_dependency 'coveralls'
  spec.add_dependency 'getopt'
  spec.add_dependency 'commander'
end
