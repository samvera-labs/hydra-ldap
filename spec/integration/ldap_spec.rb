require 'spec_helper'

describe 'Ldap service' do
  before(:all) do
    tmpdir = ENV['TMPDIR'] || ENV['TEMPDIR'] || '/tmp'
    @ldap_server = Ladle::Server.new(:port => 3897,
                                     :domain => "dc=example,dc=org",
                                     :allow_anonymous => true,
                                     :verbose => false,
                                     :ldif => 'hydra-ldap-example.ldif',
                                     :tmpdir => tmpdir,
                                     :quiet => true
                                     ).start
  end

  after(:all) do
    @ldap_server.stop if @ldap_server
  end

  describe  "Querying for users and attribute values" do
    it "should return true dd945 exists" do
      filter = Net::LDAP::Filter.eq('uid', 'dd945')
      expect(Hydra::LDAP.does_user_exist?(filter)).to be true
    end

    it "should return false abc123 does not exist" do
      filter = Net::LDAP::Filter.eq('uid', 'abc123')
      expect(Hydra::LDAP.does_user_exist?(filter)).to be false
    end

    it "should return true dd945 is unique user" do
      filter = Net::LDAP::Filter.eq('uid', 'dd945')
      expect(Hydra::LDAP.is_user_unique?(filter)).to be true
    end

    it "should return user values for dd945" do
      filter = Net::LDAP::Filter.eq('uid', 'dd945')
      expect(Hydra::LDAP.get_user(filter, ['givenName']).first[:givenname]).to eq ['Dorothy']
    end
  end

  describe "Query groups for group info" do
    it "should find a group and map the result" do
      group_code = 'Group1'
      filter = Net::LDAP::Filter.construct("(cn=#{group_code})")
      expect(Hydra::LDAP.find_group(group_code, filter, ['cn']){ |result| result.first[:cn].first }.downcase).to eq 'group1'
    end

    it "should have description, users, owners of a group" do
      group_code = 'Group1'
      filter = Net::LDAP::Filter.construct("(cn=#{group_code})")

      expect(Hydra::LDAP.title_of_group(group_code, filter){ |result| result.first[:description].first }).to eq 'Test Group1'
      expect(Hydra::LDAP.users_for_group(group_code, filter, ['uniquemember']){ |result| result.first[:uniquemember].map{ |r| r.sub(/^uid=/, '').sub(/,ou=people,dc=example,dc=org/, '') }}).to eq ['zz882', 'yy423', 'ww369']
      expect(Hydra::LDAP.owner_for_group(group_code, filter, ['owner']) { |result| result.first[:owner].map{ |r| r.sub(/^uid=/, '').sub(/,ou=people,dc=example,dc=org/, '') }}).to eq ['xx396']
    end
  end

  describe "Managing Groups" do
    before do
      attrs = {
        :cn => 'PulpFiction',
        :objectclass => 'groupofuniquenames',
        :description => 'Pulp Fiction is a movie by quentin',
        :owner => 'uid=quentin,ou=people,dc=example,dc=org',
        :uniquemember => ['uid=samuel', 'uid=uma', 'uid=john']
      }
      expect(Hydra::LDAP.create_group('PulpFiction', attrs)).to be true
    end

    after do
      Hydra::LDAP.delete_group('PulpFiction')
    end

    it "should return a list of groups owned by quentin" do
      attrs = {
        :cn => 'TrueRomance',
        :objectclass => 'groupofuniquenames',
        :description => 'True Romance is another movie by Q',
        :owner => 'uid=quentin,ou=people,dc=example,dc=org',
        :uniquemember => ['uid=christian', 'uid=patricia', 'uid=dennis']
      }
      expect(Hydra::LDAP.create_group('TrueRomance', attrs)).to be true
      filter = Net::LDAP::Filter.construct("(owner=uid=quentin,ou=people,dc=example,dc=org)")

      groups = Hydra::LDAP.groups_owned_by_user(filter, ['owner', 'cn']){ |result| result.map{ |r| r[:cn].first } }
      expect(groups).to contain_exactly('PulpFiction', 'TrueRomance')

      expect(Hydra::LDAP.delete_group('TrueRomance')).to be true
    end

    it "should add users to a group" do
      expect(Hydra::LDAP.add_users_to_group('PulpFiction', ['bruce', 'ving'])).to be true
    end

    it "should remove users from the group" do
      expect(Hydra::LDAP.remove_users_from_group('PulpFiction', ['uma', 'john'])).to be true
      group_code = 'PulpFiction'
      filter = Net::LDAP::Filter.construct("(cn=#{group_code})")
      expect(Hydra::LDAP.users_for_group(group_code, filter, ['uniquemember']){ |result| result.first[:uniquemember].map{ |r| r.sub(/^uid=/, '').sub(/,ou=people,dc=example,dc=org/, '') }}).to eq ['samuel']
    end
  end
end
