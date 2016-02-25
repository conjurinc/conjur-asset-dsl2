require 'conjur/dsl2/planner/base'
require 'conjur/dsl2/planner/facts'

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
          facts = RoleFacts.new self
          
          facts.add_requested_grant record
          
          Array(record.roles).each do |role|
            facts.role_grants(role) do |grant|
              facts.add_existing_grant role, grant
            end
          end
          
          facts.validate!
          
          facts.grants_to_apply.each do |grant|
            roleid, memberid, admin = grant
            grant = Conjur::DSL2::Types::Grant.new
            grant.role = role_record roleid
            grant.member = Conjur::DSL2::Types::Member.new role_record(memberid)
            grant.member.admin = admin
            action grant
          end

          if record.replace
            facts.grants_to_revoke.each do |grant|
              roleid, memberid = grant
              revoke = Conjur::DSL2::Types::Revoke.new
              revoke.role = role_record roleid
              revoke.member = role_record(memberid)
              action revoke
            end
          end
        end
      end
      
      class Revoke < Base
        def do_plan
          facts = RoleFacts.new self
          
          # Load all the role members as both requested and existing grants.
          # Then revoke the Grant record, and see what's left.
          Array(record.roles).each do |role|
            facts.role_grants(role) do |grant|
              grant_record = Types::Grant.new
              grant_record.role = Types::Role.new(role.roleid)
              grant_record.member = Types::Member.new Types::Role.new(grant.member.roleid)
              grant_record.member.admin = grant.admin_option
              facts.add_requested_grant grant_record
              
              facts.add_existing_grant role, grant
            end
          end

          facts.remove_revoked_grant record
          
          facts.validate!
          
          facts.grants_to_revoke.each do |grant|
            roleid, memberid = grant
            revoke = Conjur::DSL2::Types::Revoke.new
            revoke.role = role_record roleid
            revoke.member = role_record(memberid)
            action revoke
          end
        end        
      end
    end
  end
end
