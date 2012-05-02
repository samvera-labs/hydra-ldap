# Hydra::LDAP

A gem for managing ldap groups used with hydra

## Installation

Add this line to your application's Gemfile:

    gem 'hydra-ldap'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hydra-ldap

## Usage

Create the config file (config/ldap.yml) by running:

<pre>rails generate hydra-ldap</pre>


<pre>Hydra::LDAP.create_group(code, description, owner, users)</pre>

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
