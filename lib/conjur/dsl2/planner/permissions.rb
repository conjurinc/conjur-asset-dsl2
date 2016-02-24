require 'conjur/dsl2/planner/base'
require 'set'

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
          resources = Array(record.resources)
          privileges = Array(record.privilege)
          given_permissions = Hash.new { |hash, key| hash[key] = [] }
          requested_permissions = Hash.new { |hash, key| hash[key] = [] }

          resources.each do |resource|
            permissions = begin
              JSON.parse(api.resource(resource.resourceid).get)['permissions'] 
            rescue RestClient::ResourceNotFound
              []
            end

            permissions.each do |permission|
              if privileges.member?(permission['privilege'])
                given_permissions[[permission['privilege'], permission['resource']]].push [ permission['role'], permission['grant_option'] ]
              end
            end

            privileges.each do |privilege|
              Array(record.roles).each do |role|
                requested_permissions[[privilege, resource.resourceid]].push [ role.role.roleid, !!role.admin ]
              end
            end
          end
                      
          resources.each do |resource|
            error(%Q("Resource "#{resource}" not found in [#{plan.resources_created.to_a.sort.join(', ')}])) unless resource_exists?(resource)

            privileges.each do |privilege|

              target = resource.resourceid
              given = given_permissions[[privilege, target]]
              requested = requested_permissions[[privilege, target]]

              (Set.new(requested) - Set.new(given)).each do |p|
                role, admin = p

                error(%Q(Role "#{role}" not found")) unless role_exists?(role)

                permit = Conjur::DSL2::Types::Permit.new
                permit.resource = resource_record target
                permit.privilege = privilege
                permit.role = Conjur::DSL2::Types::Member.new role_record(role)
                permit.role.admin = true if admin
                action permit
              end

              if record.replace
                (Set.new(given) - Set.new(requested)).each do |p|
                  role, admin = p
                  deny = Conjur::DSL2::Types::Deny.new
                  deny.resource = resource_record target
                  deny.privilege = privilege
                  deny.role = role_record(role)
                  action deny
                end
              end
            end
          end
        end
      end
      
      # Plans a permission denial.
      #
      # A Deny statement is generated if the permission is currently held. Otherwise, its a nop.
      class Deny < Base
        def do_plan
          resources = Array(record.resources)
          privileges = Array(record.privilege)
          given_permissions = Hash.new { |hash, key| hash[key] = [] }
      
          resources.each do |resource|
            permissions = begin
              JSON.parse(api.resource(resource.resourceid).get)['permissions'] 
            rescue RestClient::ResourceNotFound
              []
            end
      
            permissions.each do |permission|
              if privileges.member?(permission['privilege'])
                given_permissions[[permission['privilege'], permission['resource']]].push permission['role']
              end
            end
          end
                      
          resources.each do |resource|
            error(%Q("Resource "#{resource}" not found in [#{plan.resources_created.to_a.sort.join(', ')}])) unless resource_exists?(resource)
      
            privileges.each do |privilege|

              target = resource.resourceid
              given = given_permissions[[privilege, target]]
              privileges.each do |privilege|
                Array(record.roles).each do |role|
                  error(%Q(Role "#{role}" not found")) unless role_exists?(role)

                  next unless given_permissions.member?([privilege, role.roleid])
                  
                  deny = Conjur::DSL2::Types::Deny.new
                  deny.resource = resource_record resource.resourceid
                  deny.privilege = privilege
                  deny.role = role_record(role.roleid)
                  action deny
                end
              end
            end
          end
        end
      end
    end
  end
end
