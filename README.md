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


<pre>Hydra::LDAP.create_group(group_code, description, owner, users)</pre>
<pre>Hydra::LDAP.groups_for_user(user_id)</pre>
<pre>Hydra::LDAP.groups_owned_by_user(user_id)</pre>
<pre>Hydra::LDAP.delete_group(group_code)</pre>
<pre>Hydra::LDAP.add_users_to_group(group_code, users)</pre>
<pre>Hydra::LDAP.remove_users_from_group(group_code, users)</pre>

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
