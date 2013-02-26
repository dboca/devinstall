# Devinstall

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

    gem 'devinstall'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install devinstall

## Usage

Example command:

    $ devinstall --environment dev --package ui-lbgenerate --action install
 
This will build and install the package on dev environment

or

    $ devinstall --environment dev-rh --package ui-lbgenerate --action repodeploy

This will build and deploy the package for dev-rh environment

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
