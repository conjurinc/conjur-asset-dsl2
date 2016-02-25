require 'conjur/dsl2/planner/base'
require 'conjur/dsl2/planner/facts'

module Conjur
  module DSL2
    module Planner
      # Plans a permission.
      #
      # The Permit record can list multiple roles, privileges, and resources. Each privilege should
      # be allowed to each role on each resource. If the +replace+ option is set, then any existing
      # privilege on an existing resource that is *not* given should be denied.
      class Permit < Base
        def do_plan
          facts = PrivilegeFacts.new self
          
          facts.add_requested_permission record
          
          privileges = Array(record.privileges)
          Array(record.resources).each do |resource|
            facts.resource_permissions(resource, privileges) do |permission|
              facts.add_existing_permission permission
            end
          end
              
          facts.validate!

          facts.grants_to_apply.each do |grant|
            role, privilege, resource, admin = grant
            
            permit = Conjur::DSL2::Types::Permit.new
            permit.resource = resource_record resource
            permit.privilege = privilege
            permit.role = Conjur::DSL2::Types::Member.new role_record(role)
            permit.role.admin = true if admin
            action permit
          end          
        
          if record.replace
            facts.grants_to_revoke.each do |grant|
              roleid, privilege, resourceid = grant
              deny = Conjur::DSL2::Types::Deny.new
              deny.resource = resource_record resourceid
              deny.privilege = privilege
              deny.role = role_record(roleid)
              action deny
            end
          end
        end
      end
      
      # Plans a permission denial.
      #
      # A Deny statement is generated if the permission is currently held. Otherwise, its a nop.
      class Deny < Base
        def do_plan
          facts = PrivilegeFacts.new self
          
          # Load all the permissions as both requested and existing grants.
          # Then remove the Deny record, and see what's left.
          privileges = Array(record.privileges)
          Array(record.resources).each do |resource|
            facts.resource_permissions(resource, privileges) do |permission|
              permit_record = Types::Permit.new
              permit_record.role = Types::Role.new(permission['role'])
              permit_record.role.admin = permission['grant_option']
              permit_record.privilege = permission['privilege']
              permit_record.resource = Types::Resource.new(permission['resource'])
              facts.add_requested_permission permit_record
              
              facts.add_existing_permission permission
            end
          end
            
          facts.remove_revoked_permission record
          
          facts.validate!
          
          facts.grants_to_revoke.each do |grant|
            role, privilege, resource = grant
            deny = Conjur::DSL2::Types::Deny.new
            deny.resource = resource_record resource
            deny.privilege = privilege
            deny.role = role_record(role)
            action deny
          end
        end
      end
    end
  end
end
