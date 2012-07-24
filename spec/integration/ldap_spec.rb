require 'spec_helper'

describe 'Ldap service' do
  before do
    # If this line isn't true, there was a problem creating (probably already exists.
    attrs = {
      :cn => 'justin1',
      :objectclass => 'groupofnames',
      :description => 'Test Group',
      :owner => 'uid=quentin',
      :member => ['uid=kacey', 'uid=larry', 'uid=ursula']
    }
    Hydra::LDAP.create_group('justin1', attrs).should be_true
  end
  after do
    Hydra::LDAP.delete_group('justin1').should be_true
  end
  it "should have description, users, owners of a group" do
    Hydra::LDAP.title_of_group('justin1').should == 'Test Group'
    Hydra::LDAP.users_for_group('justin1').should == ['kacey', 'larry', 'ursula']
    Hydra::LDAP.owner_for_group('justin1').should == 'quentin'
  end

  describe "#groups_owned_by_user" do
    before do
      Hydra::LDAP.create_group('justin2', 'Test Group', 'quentin', ['kacey', 'larry']).should be_true
      Hydra::LDAP.create_group('justin3', 'Test Group', 'theresa', ['kacey', 'larry']).should be_true
    end
    after do
      Hydra::LDAP.delete_group('justin2').should be_true
      Hydra::LDAP.delete_group('justin3').should be_true
    end
    it "should return the list" do
      Hydra::LDAP.groups_owned_by_user('quentin').should == ['justin1', 'justin2']
    end
  end
  describe "#adding_members" do
    it "should have users and owners of a group" do
      Hydra::LDAP.add_users_to_group('justin1', ['theresa', 'penelope']).should be_true
      Hydra::LDAP.users_for_group('justin1').should == ['kacey', 'larry', 'ursula', 'theresa', 'penelope']
    end
  end
  describe "#removing_members" do
    it "should remove users from the group" do
      Hydra::LDAP.remove_users_from_group('justin1', ['kacey', 'larry']).should be_true
      Hydra::LDAP.users_for_group('justin1').should == ['ursula']
    end
  end
end
