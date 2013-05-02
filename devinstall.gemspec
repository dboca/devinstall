# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'devinstall/version'

Gem::Specification.new do |spec|
  spec.name          = 'devinstall'
  spec.version       = Devinstall::VERSION
  spec.authors       = ['Dragos Boca']
  spec.email         = %w(dboca@mail.com)
  spec.description   = %q{remote builder and installer}
  spec.summary       = %q{Copy the source files to a build host, build the packages and install builded packages}
  spec.homepage      = 'http://github.com/dboca/devinstall'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = %w(lib)

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'getopt'
  spec.add_development_dependency 'rspec'
end
