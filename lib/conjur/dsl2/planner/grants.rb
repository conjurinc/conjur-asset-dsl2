require 'conjur/dsl2/planner/base'
require 'conjur/dsl2/planner/role_facts'

module Conjur
  module DSL2
    module Planner
      class Grant < Base
        # Plans a role grant.
        # 
        # The Grant record can list multiple roles and members. Each member should
        # be granted every role. If the +replace+ option is set, then any existing
        # grant on a role that is *not* given should be revoked, except for role admins.
        def do_plan
          roles = Array(record.roles)
          members = Array(record.members)
          given_grants = Hash.new { |hash, key| hash[key] = [] }
          given_admins = Set.new
          requested_grants = Hash.new { |hash, key| hash[key] = [] }

          verify_roles_available roles + members.map(&:role)

          roles.each do |role|
            grants = begin
              api.role(role.roleid).members
            rescue RestClient::ResourceNotFound
              []
            end
            
            grants.each do |grant|
              member_roleid = grant.member.roleid
              given_grants[role.roleid].push [ member_roleid, grant.admin_option ]
              given_admins << member_roleid if grant.admin_option
            end
            members.each do |member|
              requested_grants[role.roleid].push [ member.role.roleid, !!member.admin ]
            end
          end
          
          roles.each do |role|
            roleid = role.roleid
            given = given_grants[roleid]
            requested = requested_grants[roleid]
            
            (Set.new(requested) - Set.new(given)).each do |p|
              member, admin = p
              grant = Conjur::DSL2::Types::Grant.new
              grant.role = role_record roleid
              grant.member = Conjur::DSL2::Types::Member.new role_record(member)
              grant.member.admin = true if admin
              action grant
            end

            if record.replace
              (Set.new(given) - Set.new(requested)).each do |p|
                member, _ = p
                member_roleid = role_record(member).roleid
                next if given_admins.member?(member_roleid)
                revoke = Conjur::DSL2::Types::Revoke.new
                revoke.role = role_record roleid
                revoke.member = role_record(member)
                action revoke
              end
            end
          end
        end
      end
      
      class Revoke < Base
        def do_plan
          roles = Array(record.roles)
          members = Array(record.members)
          given_grants = Hash.new { |hash, key| hash[key] = [] }

          verify_roles_available roles + members

          roles.each do |role|
            grants = begin
              api.role(role.roleid).members
            rescue RestClient::ResourceNotFound
              []
            end
            
            grants.each do |grant|
              member_roleid = grant.member.roleid
              given_grants[role.roleid].push member_roleid
            end
          end
          
          roles.each do |role|
            roleid = role.roleid
            given = given_grants[roleid]
            members.each do |member|
              next unless given.member?(member.roleid)
          
              revoke = Conjur::DSL2::Types::Revoke.new
              revoke.role = role
              revoke.member = member
              action revoke
            end
          end
        end        
      end
    end
  end
end
