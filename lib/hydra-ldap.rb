require "hydra/ldap/version"
require "net/ldap"
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/hash/indifferent_access'
require 'yaml'
require 'rails'

module Hydra
  module LDAP
      # Your code goes here...
    class NoUsersError < StandardError; end
    class MissingOwnerError < StandardError; end
    class GroupNotFound < StandardError; end
   
    def self.connection
      @ldap_conn ||= Net::LDAP.new(ldap_connection_config) 
    end

    def self.ldap_connection_config
      return @ldap_connection_config if @ldap_connection_config
      @ldap_connection_config = {}
      yml = ldap_config
      @ldap_connection_config[:host] = yml[:host]
      @ldap_connection_config[:port] = yml[:port]
      if yml[:username] && yml[:password]
        @ldap_connection_config[:auth]={:method=>:simple}
        @ldap_connection_config[:auth][:username] = yml[:username]
        @ldap_connection_config[:auth][:password] = yml[:password]
      end
      @ldap_connection_config
    end

    def self.ldap_config
      root = Rails.root || '.'
      env = Rails.env || 'test'
      @ldap_config ||= YAML::load(ERB.new(IO.read(File.join(root, 'config', 'hydra-ldap.yml'))).result)[env].with_indifferent_access
    end

    def self.group_base
      ldap_config[:group_base]
    end

    def self.treebase
      ldap_config[:base]
    end

    def self.dn(code)
      dn = "cn=#{code},#{group_base}"
    end

    #def self.create_group(code, description, owner, users)
    # dn => dn(code)
    # attributes = {
    #  :cn => code,
    #  :objectclass => "groupofnames",
    #  :description => description,
    #  :member=>users.map {|u| "uid=#{u}"},
    #  :owner=>"uid=#{owner}"
    # }
    def self.create_group(dn, attributes)
      raise NoUsersError, "Unable to persist a group without users" unless users.present?
      raise MissingOwnerError, "Unable to persist a group without owner" unless owner
      #connection.add(:dn=>dn(code), :attributes=>attributes)
      connection.add(:dn=>dn, :attributes=>attributes)
    end

    def self.delete_group(dn)
      connection.delete(:dn=>dn)
    end

    # same as
    # ldapsearch -h ec2-107-20-53-121.compute-1.amazonaws.com -p 389 -x -b dc=example,dc=com -D "cn=admin,dc=example,dc=com" -W "(&(objectClass=groupofnames)(member=uid=vanessa))" cn
    # Northwestern passes attributes=['cn']
    # PSU filter=Net::LDAP::Filter.eq('uid', uid)
    # NW filter=Net::LDAP::Filter.construct("(&(objectClass=groupofnames)(member=uid=#{uid}))"))
    def self.groups_for_user(filter, attributes=['psMemberOf'], &block) 
      result = connection.search(:base=>group_base, :filter => filter, :attributes => attributes)
      block.call(result)
    end
  
    # NW - return result.map{|r| r[:cn].first}
    def self.groups_owned_by_user(filter, attributes=['cn'], &block) 
      result = connection.search(:base=>group_base, :filter=> filter, :attributes=>attributes)
      block.call(result)
    end

    # result[:description].first
    def self.title_of_group(group_code, &block)
      result = find_group(group_code)
      block.call(result)
    end

    # result[:member].map { |v| v.sub(/^uid=/, '') }
    def self.users_for_group(group_code, &block)
      result = find_group(group_code)
      block.call(result)
    end

    # result[:owner].first.sub(/^uid=/, '')
    def self.owner_for_group(group_code, &block)
      result = find_group(group_code)
      block.call(result)
    end

    def self.add_users_to_group(group_code, users)
      invalidate_cache(group_code)
      ops = []
      users.each do |u|
        ops << [:add, :member, "uid=#{u}"]
      end
      connection.modify(:dn=>dn(group_code), :operations=>ops)
    end

    def self.remove_users_from_group(group_code, users)
      invalidate_cache(group_code)
      ops = []
      users.each do |u|
        ops << [:delete, :member, "uid=#{u}"]
      end
      connection.modify(:dn=>dn(group_code), :operations=>ops)
    end

    def self.invalidate_cache(group_code)
      @cache ||= {}
      @cache[group_code] = nil
    end
    
    # NW result = connection.search(:base=>group_base, :filter=> Net::LDAP::Filter.construct("(&(objectClass=groupofnames)(cn=#{group_code}))"), :attributes=>['member', 'owner', 'description'])
    # result.first.each do |k, v|
    #  val[k] = v
    # end
    def self.find_group(group_code, filter, attributes, &block)
      @cache ||= {}
      return @cache[group_code] if @cache[group_code]
      result = connection.search(:base=>group_base, :filter=> filter, :attributes=>attributes)
      val = {}
      raise GroupNotFound, "Can't find group '#{group_code}' in ldap" unless result.first
      block.call(result)
      #puts "Val is: #{val}"
      @cache[group_code] = val
    end

    def self.get_user(filter, attribute=[])
      result = connection.search(:base=>group_base, :filter => filter, :attributes => attribute)
      return result
    end

    # hits = connection.search(:base=>group_base, :filter=>Net::LDAP::Filter.eq('uid', uid))
    def self.does_user_exist?(filter)
      hits = connection.search(:base=>group_base, :filter=>filter)
      return !hits.empty?
    end

    # hits = connection.search(:base=>group_base, :filter=>Net::LDAP::Filter.eq('uid', uid))
    def self.is_user_unique?(uid)
      hits = connection.search(:base=>group_base, :filter=>filter)
      return hits.count == 1
    end

    # hits = connection.search(:base=>group_base, :filter=>Net::LDAP::Filter.eq('cn', cn))
    def self.does_group_exist?(filter)
      hits = connection.search(:base=>group_base, :filter=>filter)
      return hits.count == 1
    end

  end
end

require 'hydra/ldap/engine' if defined?(Rails)

