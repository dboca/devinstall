require 'rspec'
require 'devinstall'

describe 'Packages' do
  before(:all) do
    Devinstall::Settings.instance.load! './spec/assets/example_01.yml' ## use defaults for type and env
  end

  it 'should include the correct file' do
    pk=Devinstall::Package.new(@package, @type, @env)
    expect(pk.singleton_class.include?(Pkg::Deb)).to be true
  end

  describe 'pkg_deb' do
    it 'should pretend to build a package' do
      $dry=true
      pk  =Devinstall::Package.new(@package, @type, @env)
      out = capture_output { pk.build(@package, @type, @env) }
      expect(out).to match(/^Building/)
    end

    it 'should pretend to upload a package' do
      $dry=true
      pk  =Devinstall::Package.new(@package, @type, @env)
      out = capture_output { pk.upload(@package, @type, @env) }
      expect(out).to match(/^Upload/)
    end

    it 'should pretend to test a package' do
      $dry=true
      pk  =Devinstall::Package.new(@package, @type, @env)
      out = capture_output { pk.run_tests(@package, @type, @env) }
      expect(out).to match(/^Running/)
    end

    it 'should pretend to install a package' do
      $dry=true
      pk  =Devinstall::Package.new(@package, @type, @env)
      out = capture_output { pk.install(@package, @type, @env) }
      expect(out).to match(/^Installing/)
    end
  end

end

