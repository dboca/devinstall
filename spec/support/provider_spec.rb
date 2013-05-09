require 'rspec'
require 'devinstall'

describe 'Provider' do
  before do
  @package, @type, @env, @action = :devinstall, :deb, :dev, :install
#  config=Devinstall::Settings.instance
  end

  it 'should load the correct (Provider::Ssh) plugin' do
    provider = Devinstall::Provider.new(@package, @type, @env, @action)
    expect(provider.singleton_class.include? Provider::Ssh).to be_true
  end
end
