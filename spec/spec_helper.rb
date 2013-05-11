require 'coveralls'
Coveralls.wear!

require 'devinstall/settings'

def clean_config
  Devinstall::Settings::FILES.clear
  Devinstall::Settings::SETTINGS.clear
  Devinstall::Settings::PROVIDERS.clear
end

def capture_output
  old_output=$stdout
  $stdout   =StringIO.new
  yield
  res    =$stdout.string
  $stdout=old_output
  res
end

RSpec.configure do |c|
  c.before(:all) do
    @config=Devinstall::Settings.instance
    clean_config
    @package, @type, @env, @action = :devinstall, :deb, nil, :install
    $verbose                       =true
  end
end

Dir[File.expand_path('../support/**/*_spec.rb', __FILE__)].sort.each { |f| require f }

