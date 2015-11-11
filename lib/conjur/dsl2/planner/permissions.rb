require 'conjur/dsl2/planner/base'
require 'set'

module Conjur
  module DSL2
    module Planner
      # Plans a permission.
      # The Permit record can list multiple roles, privileges, and resources. Each privilege should
      # be allowed to each role on each resource. If the +exclusive+ option is set, then any existing
      # privilege on an existing resource that is *not* given should be denied.
      class Permit < Base
        def plan plan
          given_permissions = Set.new
          requested_permissions = Set.new
          Array(record.resources).each do |resource|
            api.resource(resource.resourceid default_account).get['permissions'].each do |permission|
              given_permissions.add [ permission['role'], permission['privilege'], permission['resource'], permission['grant_option'] ]
            end
            Array(record.privileges).each do |privilege|
              Array(record.roles).each do |role|
                requested_permissions.add [ role.role.roleid(default_account), privilege, resource.resourceid(default_account), !!role.admin ]
              end
            end
          end
          
          (requested_permissions - given_permissions).each do |p|
            role, privilege, resource, admin = p
            account, kind, id = resource.split(':', 3)
            plan.action [ "PUT", "authz/#{account}/resources/#{kind}/#{id}?permit", { privilege: privilege, role: role, grant_option: admin } ]
          end
          if record.exclusive
            (given_permissions - requested_permissions).each do |p|
              role, privilege, resource, admin = p
              account, kind, id = resource.split(':', 3)
              plan.action [ "PUT", "authz/#{account}/resources/#{kind}/#{id}?deny", { privilege: privilege, role: role } ]
            end
          end
        end
      end
    end
  end
end
