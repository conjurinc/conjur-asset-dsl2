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
        def do_plan
          given_permissions = Set.new
          requested_permissions = Set.new
          Array(record.resources).each do |resource|
            permissions = begin
              JSON.parse(api.resource(scoped_resourceid(resource)).get)['permissions'] 
            rescue RestClient::ResourceNotFound
              []
            end
            permissions.each do |permission|
              given_permissions.add [ permission['role'], permission['privilege'], permission['resource'], permission['grant_option'] ]
            end
            Array(record.privileges).each do |privilege|
              Array(record.roles).each do |role|
                requested_permissions.add [ scoped_roleid(role.role), privilege, scoped_resourceid(resource), !!role.admin ]
              end
            end
          end
          
          privileges = requested_permissions.map{|row| row[1]}
            
          Array(record.resources).each do |resource|
            privileges.each do |privilege|
              scoped_given = Set.new(given_permissions.select do |p|
                p[1] == privilege && p[2] == scoped_resourceid(resource)
              end)
              scoped_requested = Set.new(requested_permissions.select do |p|
                p[1] == privilege && p[2] == scoped_resourceid(resource)
              end)
              
              (scoped_requested - scoped_given).each do |p|
                role, privilege, target, admin = p
                account, kind, id = target.split(':', 3)
                action({
                  'service' => 'authz',
                  'type' => 'resource',
                  'method' => 'post',
                  'action' => 'permit',
                  'path' => "authz/#{account}/resources/#{kind}/#{id}?permit",
                  'parameters' => { "privilege" => privilege, "role" => role, "grant_option" => admin }
                })
              end
              if record.exclusive
                (scoped_given - scoped_requested).each do |p|
                  role, privilege, target, admin = p
                  account, kind, id = target.split(':', 3)
                  action({
                    'service' => 'authz',
                    'type' => 'resource',
                    'method' => 'post',
                    'action' => 'deny',
                    'path' => "authz/#{account}/resources/#{kind}/#{id}?deny", 
                    'parameters' => { "privilege" => privilege, "role" => role }
                  })
                end
              end
            end
          end
        end
      end
    end
  end
end
