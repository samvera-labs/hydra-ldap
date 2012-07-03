require "hydra/ldap/version"
require "net/ldap"
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/hash/indifferent_access'
require 'yaml'
require 'rails'

module Hydra
  module LDAP
    extend ActiveSupport::Concern
    module ClassMethods
      # Your code goes here...
      class NoUsersError < StandardError; end
      class MissingOwnerError < StandardError; end
      class GroupNotFound < StandardError; end
     
      def connection
        @ldap_conn ||= Net::LDAP.new(ldap_connection_config) 
      end

      def ldap_connection_config
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

      def ldap_config
        root = Rails.root || '.'
        env = Rails.env || 'test'
        @ldap_config ||= YAML::load(ERB.new(IO.read(File.join(root, 'config', 'hydra-ldap.yml'))).result)[env].with_indifferent_access
      end

      def group_base
        ldap_config[:group_base]
      end

      def treebase
        ldap_config[:base]
      end

      def dn(code)
        dn = "cn=#{code},#{group_base}"
      end

      def create_group(code, description, owner, users)
        raise NoUsersError, "Unable to persist a group without users" unless users.present?
        raise MissingOwnerError, "Unable to persist a group without owner" unless owner
        attributes = {
          :cn => code,
          :objectclass => "groupofnames",
          :description => description,
          :member=>users.map {|u| "uid=#{u}"},
          :owner=>"uid=#{owner}"
        }
        connection.add(:dn=>dn(code), :attributes=>attributes)
      end

      def delete_group(code)
        connection.delete(:dn=>dn(code))
      end

      # same as
      # ldapsearch -h ec2-107-20-53-121.compute-1.amazonaws.com -p 389 -x -b dc=example,dc=com -D "cn=admin,dc=example,dc=com" -W "(&(objectClass=groupofnames)(member=uid=vanessa))" cn
      # Northwestern passes attributes=['cn']
      def groups_for_user(uid, attributes=['psMemberOf'])
        result = connection.search(:base=>group_base, :filter => filter_groups_for_user(uid), :attributes => attributes)
        return result_groups_for_user(result)
      end
    
      def filter_groups_for_user(uid)
        raise "You must extend hydra-ldap in your app and define this method."
      end 

      def result_groups_for_user(result)
        raise "You must extend hydra-ldap in your app and define this method."
      end 

      def groups_owned_by_user(uid)
        result = connection.search(:base=>group_base, :filter=> Net::LDAP::Filter.construct("(&(objectClass=groupofnames)(owner=uid=#{uid}))"), :attributes=>['cn'])
        result.map{|r| r[:cn].first}
      end

      def title_of_group(group_code)
        result = find_group(group_code)
        result[:description].first
      end

      def users_for_group(group_code)
        result = find_group(group_code)
        result[:member].map { |v| v.sub(/^uid=/, '') }
      end

      def owner_for_group(group_code)
        result = find_group(group_code)
        result[:owner].first.sub(/^uid=/, '')
      end

      def add_users_to_group(group_code, users)
        invalidate_cache(group_code)
        ops = []
        users.each do |u|
          ops << [:add, :member, "uid=#{u}"]
        end
        connection.modify(:dn=>dn(group_code), :operations=>ops)
      end

      def remove_users_from_group(group_code, users)
        invalidate_cache(group_code)
        ops = []
        users.each do |u|
          ops << [:delete, :member, "uid=#{u}"]
        end
        connection.modify(:dn=>dn(group_code), :operations=>ops)
      end

      def invalidate_cache(group_code)
        @cache ||= {}
        @cache[group_code] = nil
      end
      
      def find_group(group_code)
        @cache ||= {}
        return @cache[group_code] if @cache[group_code]
        result = connection.search(:base=>group_base, :filter=> Net::LDAP::Filter.construct("(&(objectClass=groupofnames)(cn=#{group_code}))"), :attributes=>['member', 'owner', 'description'])
        val = {}
        raise GroupNotFound, "Can't find group '#{group_code}' in ldap" unless result.first
        result.first.each do |k, v|
          val[k] = v
        end
        #puts "Val is: #{val}"
        @cache[group_code] = val
      end
    
      def does_user_exist?(uid)
        hits = connection.search(:base=>group_base, :filter=>Net::LDAP::Filter.eq('uid', uid))
        return !hits.empty?
      end

      def is_user_unique?(uid)
        hits = connection.search(:base=>group_base, :filter=>Net::LDAP::Filter.eq('uid', uid))
        return hits.count == 1
      end

      def does_group_exist?(cn)
        hits = connection.search(:base=>group_base, :filter=>Net::LDAP::Filter.eq('cn', cn))
        return hits.count == 1
      end

    end
  end
end

require 'hydra/ldap/engine' if defined?(Rails)

