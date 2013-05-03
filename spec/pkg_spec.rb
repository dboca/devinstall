require 'rspec'
require 'devinstall'

describe 'Packages' do
  config=Devinstall::Settings.instance
  config.load! './doc/example.yml' ## use defaults for type and env

  package=:devinstall
  type=:deb
  env=nil

  it 'should include the correct file' do
    pk=Devinstall::Package.new(package, type, env)
    expect(pk.singleton_class.include?(Pkg::Deb)).to be_true
  end
end
