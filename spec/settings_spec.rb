require 'rspec'

require 'devinstall/settings'

describe 'Set' do

  it 'should load at  init' do
    @config=Devinstall::Settings.new("../doc/example.yml")
    expect(@config).to be_an_instance_of(Devinstall::Settings)
  end
  it 'should have defaults' do
    @config=Devinstall::Settings.new("../doc/example.yml")
    expect(@config.defaults).to be_true
  end
  it 'should have a static default' do
    @config=Devinstall::Settings.new("../doc/example.yml")
    expect(Devinstall::Settings.defaults(:package)).to be(@config.defaults(:package))
  end
end
