require 'devinstall/utils'
## Work in progress
module Pkg
  module RpmWorking
#  @type=:rpm
    include Utils

    def get_info(pkg, type, env)
      config=Devinstall::Settings.instance
      folder=config.local(:folder, pkg: pkg, type: type, env: env)
      rpm_spec = File.expand_path "#{folder}/#{pkg}.rpm.spec"
      unless File.exists? rpm_spec
        exit! "No 'debian/changelog' found in specified :local:folder (#{folder})"
      end
      package_version = File.open(rpm_spec, 'r') { |f| f.gets.chomp.sub(/^.*\((.*)\).*$/, '\1') }
      package_release = config.build(pkg: pkg, type: type, env: env)[:arch]
      {version: package_version,
        files: {rpm: "#{pkg}.#{package_version}.#{package_release}.rpm"},
        to_install: [:rpm],
        to_upload:  [:rpm]
      }
    end
  end
end
