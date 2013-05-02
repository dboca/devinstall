require 'rspec'

require 'devinstall/settings'

describe 'Settings' do
  config=Devinstall::Settings.instance
  config.load! "./doc/example.yml"

  it 'should load at init' do
    expect(config).to be_an_instance_of(Devinstall::Settings)
    [:defaults, :base, :local, :build, :install, :tests, :packages, :repos].each do |p|
      expect(config.send(p)).to be_true
    end # all sections loaded!
  end

  it 'should have defaults' do
    expect(config.defaults).to be_true
  end

  it 'should have a static default' do
    expect(Devinstall::Settings.defaults(:package)).to be(config.defaults(:package))
  end

  it 'should raise errors for unknown keys' do
    expect{config.defaults :none}.to raise_error(Devinstall::UnknownKeyError)
  end

  it 'should raise errors for undefined keys' do
    expect{config.tests(:provider)}.to raise_error(Devinstall::KeyNotDefinedError)
  end
end
