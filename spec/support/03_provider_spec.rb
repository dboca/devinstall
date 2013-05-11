require 'rspec'
require 'devinstall'

describe 'Provider' do

  before(:all) do
    Devinstall::Settings.instance.load! './spec/assets/example_01.yml' ## use defaults for type and env
  end

  it 'should load the correct (Provider::Ssh) plugin' do
    provider = Devinstall::Provider.new(@package, @type, @env, @action)
    expect(provider.singleton_class.include? Provider::Ssh).to be_true
  end
end
