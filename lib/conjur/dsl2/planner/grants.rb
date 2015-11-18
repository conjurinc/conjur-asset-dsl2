require 'conjur/dsl2/planner/base'

module Conjur
  module DSL2
    module Planner
      class Grant < Base
        # Plans a role grant.
        # 
        # The Grant record can list multiple roles and members. Each member should
        # be granted every role. If the +replace+ option is set, then any existing
        # grant on a role that is *not* given should be revoked.
        def do_plan
          roles = Array(record.roles)
          members = Array(record.members)
          given_grants = Hash.new { |hash, key| hash[key] = [] }
          requested_grants = Hash.new { |hash, key| hash[key] = [] }
          roles.each do |role|
            grants = begin
              api.role(scoped_roleid(role)).members
            rescue RestClient::ResourceNotFound
              []
            end
            grants.each do |grant|
              # Don't revoke admins from roles
              next if grant.admin_option
              given_grants[scoped_roleid(role)].push [ grant.member.roleid, grant.admin_option ]
            end
            members.each do |member|
              requested_grants[scoped_roleid(role)].push [ scoped_roleid(member.role), !!member.admin ]
            end
          end
          
          roles.each do |role|
            roleid = scoped_roleid(role)
            given = given_grants[roleid]
            requested = requested_grants[roleid]
            
            (Set.new(requested) - Set.new(given)).each do |p|
              member, admin = p
              account, kind, id = roleid.split(':', 3)
              action({
                'service' => 'authz',
                'type' => 'role',
                'method' => 'put',
                'action' => 'grant',
                'path' => "authz/#{account}/roles/#{kind}/#{id}?members",
                'parameters' => { "member" => member, "admin_option" => admin },
                'description' => "Grant #{roleid} to #{member}#{admin ? ' with admin option' : ''}"
              })
            end
            if record.replace
              (Set.new(given) - Set.new(requested)).each do |p|
                member, admin = p
                account, kind, id = roleid.split(':', 3)
                action({
                  'service' => 'authz',
                  'type' => 'role',
                  'method' => 'delete',
                  'action' => 'revoke',
                  'path' => "authz/#{account}/roles/#{kind}/#{id}?members", 
                  'parameters' => { "member" => member },
                  'description' => "Revoke #{roleid} from #{member}"
                })
              end
            end
          end
        end
      end
    end
  end
end
