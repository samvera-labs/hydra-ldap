require 'spec_helper'
require 'ladle'
describe 'Ldap service' do
  before(:all) do
    @ldap_server = Ladle::Server.new(
      :port => 3897,
      :domain => "dc=example,dc=org",
      :allow_anonymous => true,
      :verbose => false,
      :ldif => 'hydra-ldap-example.ldif'
      ).start
  end
  
  after(:all) do
    @ldap_server.stop if @ldap_server
  end

  describe  "Querying for users and attribute values" 
    it "should return true dd945 exists" do
      filter = Net::LDAP::Filter.eq('uid', 'dd945')
      Hydra::LDAP.does_user_exist?(filter).should be_true
    end

    it "should return false abc123 does not exist" do
      filter = Net::LDAP::Filter.eq('uid', 'abc123')
      Hydra::LDAP.does_user_exist?(filter).should_not be_true
    end

    it "should return true dd945 is unique user" do
      filter = Net::LDAP::Filter.eq('uid', 'dd945')
      Hydra::LDAP.is_user_unique?(filter).should be_true
    end

    it "should return user values for dd945" do
      filter = Net::LDAP::Filter.eq('uid', 'dd945')
      Hydra::LDAP.get_user(filter, ['givenName']).first[:givenname] == 'Dorothy'
    end


  describe "Query groups for group info"
    it "should find a group and map the result" do
      group_code = 'Group1' 
      filter = Net::LDAP::Filter.construct("(cn=#{group_code})")
      Hydra::LDAP.find_group(group_code, filter, ['cn']){ |result| result.first[:cn].first }.downcase.should == 'group1'
    end

    it "should have description, users, owners of a group" do
      group_code = 'Group1'
      filter = Net::LDAP::Filter.construct("(cn=#{group_code})")

      Hydra::LDAP.title_of_group(group_code, filter){ |result| result.first[:description].first }.should == 'Test Group1'
      Hydra::LDAP.users_for_group(group_code, filter, ['uniquemember']){ |result| result.first[:uniquemember].map{ |r| r.sub(/^uid=/, '').sub(/,ou=people,dc=example,dc=org/, '') }}.should == ['zz882', 'yy423', 'ww369']
      Hydra::LDAP.owner_for_group(group_code, filter, ['owner']) { |result| result.first[:owner].map{ |r| r.sub(/^uid=/, '').sub(/,ou=people,dc=example,dc=org/, '') }}.should == ['xx396']
    end

    describe "Managing Groups"
      before do
        attrs = {
          :cn => 'PF',
          :objectclass => 'groupofuniquenames',
          :description => 'Pulp Fiction is a movie by quentin',
          :owner => 'uid=quentin,ou=people,dc=example,dc=org',
          :uniquemember => ['uid=samuel', 'uid=uma', 'uid=john']
        }
        Hydra::LDAP.create_group('PulpFiction', attrs).should be_true
      end

      after do
        Hydra::LDAP.delete_group('PulpFiction').should be_true
      end

      it "should return a list of groups owned by quentin" do
        attrs = {
          :cn => 'TR',
          :objectclass => 'groupofuniquenames',
          :description => 'True Romance is another movie by Q',
          :owner => 'uid=quentin,ou=people,dc=example,dc=org',
          :uniquemember => ['uid=christian', 'uid=patricia', 'uid=dennis']
        }
        Hydra::LDAP.create_group('TrueRomance', attrs).should be_true
        filter = Net::LDAP::Filter.construct("(owner=uid=quentin,ou=people,dc=example,dc=org)")

        Hydra::LDAP.groups_owned_by_user(filter, ['owner', 'cn']){ |result| result.map{ |r| r[:cn].first } }.should == ['PulpFiction', 'TrueRomance']

        Hydra::LDAP.delete_group('TrueRomance').should be_true
      end

      it "should add users to a group" do
        Hydra::LDAP.add_users_to_group('PulpFiction', ['bruce', 'ving']).should be_true
      end

      it "should remove users from the group" do
        Hydra::LDAP.remove_users_from_group('PulpFiction', ['uma', 'john']).should be_true
        group_code = 'PulpFiction'
        filter = Net::LDAP::Filter.construct("(cn=#{group_code})")
        Hydra::LDAP.users_for_group(group_code, filter, ['uniquemember']){ |result| result.first[:uniquemember].map{ |r| r.sub(/^uid=/, '').sub(/,ou=people,dc=example,dc=org/, '') }}.should == ['samuel']
      end
      
end 
