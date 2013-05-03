require 'devinstall/utils'

module Pkg
  module Deb
#  @type=:deb
    include Utils

    def get_info(pkg, type, env)
      config=Devinstall::Settings.instance
      folder=config.local(:folder, pkg: pkg, type: type, env: env)
      deb_changelog = File.expand_path "#{folder}/#{pkg}/debian/changelog"
      unless File.exists? deb_changelog
        exit! "No 'debian/changelog' found in specified :local:folder (#{folder})"
      end
      package_version = File.open(deb_changelog, 'r') { |f| f.gets.chomp.sub(/^.*\((.*)\).*$/, '\1') }
      p_name = "#{pkg}_#{package_version}"
      arch = config.build(pkg: pkg, type: type, env: env)[:arch]
      {version: package_version,
       files:
           {deb: "#{p_name}_#{arch}.deb",
            tgz: "#{p_name}.tar.gz",
            dsc: "#{p_name}.dsc",
            chg: "#{p_name}_amd64.changes"},
       to_install: [:deb],
       to_upload: [:deb, :tgz, :dsc, :chg]
      }
    rescue IOError => e
      exit! "IO Error while opening #{deb_changelog}\n Aborting \n #{e.message}"
    end
  end
end
