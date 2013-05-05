require 'rspec'

require 'devinstall/settings'

describe 'Settings' do
  config=Devinstall::Settings.instance
  config.load! './doc/example.yml' ## use defaults for type and env

  package=:devinstall
  type=:deb
  env=nil

  $verbose=true

  it 'should load an existig file' do
    expect(config.load!('doc/example.yml')).to be_true
  end

  it 'should not load an unexisting file' do
    expect(config.load!('doc/unexisting.yml')).to be_false
  end

  it 'should load at init' do
    expect(config).to be_an_instance_of(Devinstall::Settings)
    [:defaults, :local, :build, :install, :tests, :repos].each do |p|
      expect(config.respond_to? p).to be_true
    end # all sections loaded!
  end

  it 'should have a method defaults' do
    expect(config.respond_to? :defaults).to be_true
  end

  it 'the method "defaults" should have only one argument' do
    expect(config.defaults(:type)).to eq "deb"
  end

  it 'should instantiate a new "Action" when hashes are given' do
    expect(config.build(type:'deb', env:'dev', pkg:package)).to be_an_instance_of(Devinstall::Settings::Action)
  end

  it 'should instantiata a new "Action" when partial hashes are given' do
    expect(config.build(pkg:package)).to be_an_instance_of(Devinstall::Settings::Action)
  end

  it 'should raise "UnknownKeys" errors for unknown keys' do
    expect{config.defaults :none}.to raise_error(Devinstall::UnknownKeyError)
  end

  it 'should raise "KeyNotDefinedError" errors for undefined keys' do
    expect{config.tests(:provider, pkg:package)}.to raise_error(Devinstall::KeyNotDefinedError)
  end

  it 'should produce a value if all arguments are valid' do
    expect(config.build(:command, pkg:package)).to eq('cd %f/%p && dpkg-buildpackage')
  end
end
describe "Action" do
  config=Devinstall::Settings.instance
  config.load! './doc/example.yml' ## use defaults for type and env

  package=:devinstall
  type=:deb
  env=nil

  $verbose=true

  it 'should have a [] method' do
    rr=config.build(pkg:package, type:type, env:env)
    expect(rr[:target]).to eq('rs')
  end

  it 'should enumerate all defined values' do
    ar=[]
    config.build(pkg:package, type:type, env:env).each do |k,_|
      ar << k
    end
    expect(ar.sort == [:folder, :command, :provider, :type, :arch, :target].sort ).to be_true
  end
end
