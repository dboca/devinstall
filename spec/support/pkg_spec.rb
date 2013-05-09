require 'rspec'
require 'devinstall'

describe 'Packages' do
  config=Devinstall::Settings.instance
  config.load! './spec/assets/example_01.yml' ## use defaults for type and env

  package=:devinstall
  type=:deb
  env=nil

  it 'should include the correct file' do
    pk=Devinstall::Package.new(package, type, env)
    expect(pk.singleton_class.include?(Pkg::Deb)).to be_true
  end

describe 'pkg_deb' do
  it 'should pretend to build a package' do
    $dry=true
    pk=Devinstall::Package.new(package, type, env)
    pk.build(package, type, env){
      STDOUT.should_receive(:puts).with('Building')
    }
  end

  it 'should pretend to upload a package' do
    $dry=true
    pk=Devinstall::Package.new(package, type, env)
    pk.upload(package, type, env){
      STDOUT.should_receive(:puts).with('Uploading')
    }
  end

  it 'should pretend to test a package' do
    $dry=true
    pk=Devinstall::Package.new(package, type, env)
    pk.run_tests(package, type, env){
      STDOUT.should_receive(:puts).with('Uploading')
    }
  end

  it 'should pretend to install a package' do
    $dry=true
    pk=Devinstall::Package.new(package, type, env)
    pk.install(package, type, env){
      STDOUT.should_receive(:puts).with('Uploading')
    }
  end

end
end
