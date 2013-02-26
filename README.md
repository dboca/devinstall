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

Example command:

    $ devinstall –config ./config.yml --environment dev --package ui-lbgenerate --action install

This will build and install the package on dev environment

or

    $ devinstall --config ./config.yml --environment dev-rh --package ui-lbgenerate --action upload

This will build and upload package to repository for dev-rh environment as defined in config.yml

The command line parameters are:

	--config: the config file (defaults to ./config.yml)

	--environment: the environment for the install or upload action

	-- package: the package to be built and installed/uploaded

	--type: only for –action build and specifies the package type (deb, rpm, tar.gz, arc....)

	--action: can be build (require also --type), install (require --environment) or upload (also require --environment)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
