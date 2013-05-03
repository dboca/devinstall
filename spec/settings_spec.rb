require 'rspec'

require 'devinstall/settings'

describe 'Settings' do
  config=Devinstall::Settings.instance
  config.load! './doc/example.yml' ## use defaults for type and env

  package=:devinstall
  type=:deb
  env=nil

  it 'should load an existig file' do
    expect(config.load!('doc/example.yml')).to be_true
  end

  it 'should not load an unexisting file' do
    expect(config.load!('doc/unexisting.yml')).to be_false
  end

  it 'should load at init' do
    expect(config).to be_an_instance_of(Devinstall::Settings)
    [:defaults, :base, :local, :build, :install, :tests, :repos].each do |p|
      expect(config.respond_to? p).to be_true
    end # all sections loaded!
  end

  it 'should have defaults' do
    expect(config.defaults).to be_true
  end

  it 'should produce validators when hashes are given' do
    expect(config.build(type:'deb', env:'dev', pkg:package)).to be_an_instance_of(Devinstall::Settings::Action)
  end

  it 'should produce validators when partial hashes are given' do
    expect(config.build(pkg:package)).to be_an_instance_of(Devinstall::Settings::Action)
  end

  it 'should validate correct data' do
    expect(rr=config.build(pkg:package, type:type, env:env)).to be_an_instance_of(Devinstall::Settings::Action)
    expect(rr.valid?).to be_true
  end

  it 'should not validate incorrect data' do
    expect(rr=config.build(pkg:package, type: :rpm, env:env)).to be_an_instance_of(Devinstall::Settings::Action)
    expect(rr.valid?).to be_false
  end

  it 'should raise errors for unknown keys' do
    expect{config.defaults :none}.to raise_error(Devinstall::UnknownKeyError)
  end

  it 'should raise errors for undefined keys' do
    expect{config.tests(:provider, pkg:package)}.to raise_error(Devinstall::KeyNotDefinedError)
  end

  it 'should produce a value if aok' do
    expect(config.build(:user, pkg:package)).to eq('dboca')
  end

  it 'validator should have a [] method' do
    rr=config.build(pkg:package, type:type, env:env)
    expect(rr[:user]).to eq('dboca')
  end

  it 'should enumerate all defined values' do
    ar=[]
    config.build(pkg:package, type:type, env:env).each do |k,v|
       ar << k
    end
    expect(ar).to eql([:user, :host, :folder, :target, :arch, :command, :provider])
  end

end
