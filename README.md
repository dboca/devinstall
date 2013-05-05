# Devinstall  [![Gem Version][GV img]][Gem Version]

[Gem Version]: https://rubygems.org/gems/devinstall

[GV img]: https://badge.fury.io/rb/devinstall.png

This is a poor man automatic package builder / installer / deployer.

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

When you install the gem, the installer automaticaly install a program named pkg-tool. 
All the actions can be done via this tool.

The general command line syntax is:

	$ pkg_tool <action> [<package>] [--env <environment>] [--type <type>] [--config <config_file>]

Where:

### Action can be one of the:

    build

Builds the package on the `build/env/host` and copy the package file(s) back in the `base/temp` folder

    install

Build (using `build` command) and install the builded package on the `install/env/host`

    tests

Run the tests described in `test` section of the configuration file

    upload

Build the package, run the tests and upload thr file to the repo

### The switches

The command line switches are:

  --config: the config file (defaults to ./devinstall.yml)

  --env: the environment for the install or upload action

  --type: only for –action build and specifies the package type (deb, rpm, tar.gz, arc....)

The switches override the defaults in the config file

## Example command:

    $ pkg-tool install devinstall –config ./config.yml --env dev

This will build and install the package "devinstall" on dev environment

or

    $ pkg-tool upload devinstall --config ./config.yml --env dev-rh

This will build and upload package "devinstall" to repository for dev-rh environment as defined in config.yml

## The config file

In order to set all the variables and to define commands to do when building or installing you need a configuration file.

The said config file have simple YAML structure and should define the folowing parameters:

    local:    
      folder:
      temp:

The folder where the source/prepackaged files are on the local (developer) machine (`:folder`) and the
temporary folder where the generated packages will be downloades

    build:
      folder: 
      command:
      provider:
      type:
      arch:
      target:
      env:

In order:

  - the folder where the sources should be copied (might be ignored by some provider_plugins)

  - The command used to build the package (like `make package` or `dpkg-buildpackage`)

  - The provider for the build machine (like the `local` machine or another machine
  accessible only by SSH - `ssh` 

  - the package type ( `deb`ian, `rpm`, ...)

  - the architecture (might be ignored by some package_plugins)

  - and the folder where the package builder will put the builded packages

  - env define an environment (lyke `prod` or `QA`) for which the package will be built / installed
  Unlike the other parameters env is optional 
  
    install:
      folder:
      command:
      provider:
      type:
      arch:
      env:		
    
    repos:
      folder:
      provider:
      type:
      arch:
      env:
    
    tests:
      folder:
      command:
      provider
      env:
              
 The parameters have the same meaning as for `build:`
 `repos` reffers to the package repository
 `tests` is optional (DON'T do this) and no tests will be performend if it's missing

    defaults:
      type:
      env:
              
The default `type` and `env` if you don't use command-line switches


The order in which the parameters will be searched is:

  - local
  
    packages:
      <package_name>:
        <type>:
          <section>:  # like build: or install:
            <env>:
              <parameter>: <value>
            
              
  - or global:

      <section>:
        <env>:
          <parameter>: value

The parameters speciffied per package have priority over the global ones

In any case `env` is optional

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
