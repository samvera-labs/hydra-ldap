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

Made the filters, attributes and result parsing all parameters as frequently as possible, to try and make this
usable to many LDAP directory set ups.

It might be helpful to look at the hydra-ldap-example.ldif, config/hydra-ldap.yml and spec/integration/ldap_spec.rb to see what type of configuration the tests are running for comparison purposes.

The attributes here would change based on LDAP configuration.  
<pre>
attrs = {
  :cn => 'Test'
  :objectclass => 'groupofnames'
  :description => 'my test group contains users, and owners'
  :owner => 'uid=abc123'
  :member => ['john', 'jane', 'fido']
  }
Hydra::LDAP.create_group(group_code, attributes{})
</pre>

Examples of how to customize the results being returned, print out the cn attribute for 
the groups owned by this user (hoping these are helpful for NU).
<pre>
filter = Net::LDAP::Filter.construct("(owner=uid=quentin,ou=people,dc=example,dc=org)")
Hydra::LDAP.groups_owned_by_user(filter, ['owner', 'cn']){ |result| result.map{ |r| puts r[:cn].first } }
</pre>

<pre>
uid = 'uid'
filter=Net::LDAP::Filter.construct("(&(objectClass=groupofnames)(member=uid=#{uid}))")
attributes = ['cn']
Hydra::LDAP.groups_for_user(filter, attributes){ |result| result.map { |r| r[:cn].first }}
</pre>

<pre>
filter = Net::LDAP::Filter.construct("(cn=#{group_code})")
attributes = ['default attribute is description']
Hydra::LDAP.title_of_group(group_code, filter, attributes){ |result| result.first[:description].first }
</pre>

<pre>
filter = Net::LDAP::Filter.construct("(cn=#{group_code})")
Hydra::LDAP.users_for_group(group_code, filter, ['member']){ |result| result.first[:uniquemember].map{ |r| r.sub(/^uid=/, '') }}
</pre>

<pre>
filter = Net::LDAP::Filter.construct("(cn=#{group_code})")
Hydra::LDAP.owner_for_group(group_code, filter, ['owner']) { |result| result.first[:owner].map{ |r| r.sub(/^uid=/, '') }}
</pre>

These are all pretty similar to previous calls, if not the same signatures.
<pre>Hydra::LDAP.delete_group(group_code).should be_true</pre>


<pre>Hydra::LDAP.add_users_to_group(group_code, ['bruce', 'beth'])</pre>
<pre>Hydra::LDAP.remove_users_from_group(group_code, ['bruce'])</pre>

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
