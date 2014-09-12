require 'rspec'
require 'devinstall'
require 'pp'
describe 'Settings' do

   it 'should load an existig file' do
      res=@config.load!('./spec/assets/example_02.yml')
      expect(res).to be true
   end

   it 'should not load an unexisting file' do
      res=@config.load!('doc/unexisting.yml')
      expect(res).to be false
   end

   it 'should load at init' do
      expect(@config).to be_an_instance_of(Devinstall::Settings)
      [:defaults, :local, :build, :install, :tests, :repos].each do |p|
         expect(@config.respond_to? p).to be true
      end # all sections loaded!
   end

   it 'should have a method defaults' do
      expect(@config.respond_to? :defaults).to be true
   end

   it 'the method "defaults" should have only one argument' do
      expect(@config.defaults(:type)).to eq 'deb'
   end

   it 'should instantiate a new "Action" when hashes are given' do
      expect(@config.build(type: 'deb', env: 'dev', pkg: @package)).to be_an_instance_of(Devinstall::Settings::Action)
   end

   it 'should instantiata a new "Action" when partial hashes are given' do
      expect(@config.build(pkg: @package)).to be_an_instance_of(Devinstall::Settings::Action)
   end

   it 'should raise "UnknownKeys" errors for unknown keys' do
      expect { @config.defaults :none }.to raise_error(Devinstall::UnknownKeyError)
   end

   it 'should raise "KeyNotDefinedError" errors for undefined keys' do
      expect { @config.tests(:provider, pkg: @package) }.to raise_error(Devinstall::KeyNotDefinedError)
   end

   it 'should produce a value if all arguments are valid' do
      expect(@config.build(:command, pkg: @package)).to eq('cd %f/%p && dpkg-buildpackage')
   end

   describe 'Action' do
      it 'should have a [] method' do
         rr=@config.build(pkg: @package, type: @type, env: @env)
         expect(rr[:target]).to eq('rs')
      end

      it 'should enumerate all defined values' do
         ar=[]
         @config.build(pkg: @package, type: @type, env: @env).each { |k, _| ar << k }
         expect(ar.sort == [:folder, :command, :provider, :type, :arch, :target].sort).to be true
      end
   end
end
