# Devinstall

This is a poor man automatic builder / installer / deployer for packages.

The build happens on a remote machine (in the future on several remote machines by package type)
via external tools rsync and ssh.

The packages are installed on the remote machines also via external rsync/scp and sshsudo
(until I will implement something more appropriate in Ruby)

## Installation

Add this line to your application's Gemfile:

    gem 'devinstall'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install devinstall

## Usage

When you install the gem, the installer automaticaly create an executable named pkg-tool. 
All the actions you can do via this tool.

The general command line syntax is:

	$ pkg_tool <action> [<package>] [--env <environment>] [--type <type>] [--config <config_file>]
where:
  * action can be one of the:
  	build
Builds the package on the {{build/env/host}} and copy the package file(s) back in the {{base/temp}} folder


Example command:

    $ pkg-tool install devinstall –config ./config.yml --env dev

This will build and install the package "devinstall" on dev environment

or

    $ pkg-tool upload devinstall --config ./config.yml --env dev-rh --package ui-lbgenerate --action upload

This will build and upload package "devinstall" to repository for dev-rh environment as defined in config.yml

The command line parameters are:

	--config: the config file (defaults to ./devinstall.yml)

	--env: the environment for the install or upload action

	--type: only for –action build and specifies the package type (deb, rpm, tar.gz, arc....)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
