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
          privileges = Array(record.privileges)
          given_permissions = Hash.new { |hash, key| hash[key] = [] }
          requested_permissions = Hash.new { |hash, key| hash[key] = [] }
          resources.each do |resource|
            permissions = begin
              JSON.parse(api.resource(scoped_resourceid(resource)).get)['permissions'] 
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
                requested_permissions[[privilege, scoped_resourceid(resource)]].push [ scoped_roleid(role.role), !!role.admin ]
              end
            end
          end
                      
          resources.each do |resource|
            privileges.each do |privilege|
              target = scoped_resourceid(resource)
              given = given_permissions[[privilege, target]]
              requested = requested_permissions[[privilege, target]]
              
              (Set.new(requested) - Set.new(given)).each do |p|
                role, admin = p
                account, kind, id = target.split(':', 3)
                action({
                  'service' => 'authz',
                  'type' => 'resource',
                  'method' => 'post',
                  'action' => 'permit',
                  'path' => "authz/#{account}/resources/#{kind}/#{id}?permit",
                  'parameters' => { "privilege" => privilege, "role" => role, "grant_option" => admin },
                  'description' => "Permit role '#{role}' to '#{privilege}' resource '#{target}'#{admin ? ' with admin option' : ''}"
                })
              end
              if record.replace
                (Set.new(given) - Set.new(requested)).each do |p|
                  role, admin = p
                  account, kind, id = target.split(':', 3)
                  action({
                    'service' => 'authz',
                    'type' => 'resource',
                    'method' => 'post',
                    'action' => 'deny',
                    'path' => "authz/#{account}/resources/#{kind}/#{id}?deny", 
                    'parameters' => { "privilege" => privilege, "role" => role },
                    'description' => "Deny role '#{role}' to '#{privilege}' resource '#{target}'"
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
