module Conjur
  module Policy
    module Planner
      # Stores the state of existing and requested grants (roles or privileges).
      # 
      # The difference between the existing and requested grants can be used to determine
      # specifically what actions should be performed in order to bring the state of the server
      # into compliance with the policy.
      class BaseFacts
        attr_accessor :planner, :existing, :requested, :existing_with_admin_flag, :requested_with_admin_flag
        
        # Whether to sort the grants. By default this is off; turning it on makes the output
        # deterministic which is nice for testing.
        cattr_accessor :sort
        
        def initialize planner
          @planner = planner
          @requested = Set.new
          @requested_with_admin_flag = Set.new
          @existing  = Set.new
          @existing_with_admin_flag  = Set.new
        end
        
        def api
          planner.api
        end
        
        # Return the set of grants which are requested but not already held.
        #
        # Note that if a grant is held with a different admin option than requested,
        # re-applying with the new admin option will update the grant and create
        # the desired state.
        def grants_to_apply
          sort(requested_with_admin_flag - existing_with_admin_flag)
        end
        
        # Return the set of grants which are held but not requested.
        #
        # The admin flag is ignored by this method. So, if a grant exists (with or without
        # admin), and it is not requested (with or without admin), it is revoked. The
        # case in which the grant is held with a different admin option than requested
        # is handled by +grants_to_apply+.
        def grants_to_revoke
          sort(existing - requested)
        end
        
        def validate_role_exists! role
          planner.error("Role not found: #{role}") unless planner.role_exists?(role)
        end
        
        def validate_resource_exists! resource
          planner.error("Resource not found: #{resource}") unless planner.resource_exists?(resource)
        end
        
        protected
        
        # Sort a result if +sort+ is enabled.
        def sort result
          self.class.sort ? result.to_a.sort : result
        end
      end
      
      # Role grants are a tuple of [ roleid, member_roleid, admin_option ].
      class RoleFacts < BaseFacts
        
        # Enumerate all existing grants on the specified +role+.
        # Each grant is yielded to the block.
        def role_grants role, &block
          begin
            api.role(role.roleid).members
          rescue RestClient::ResourceNotFound
            if api.role(role.roleid).exists?
              $stderr.puts "WARNING: Unable to fetch members of role #{role.roleid}. Use 'elevate' mode, or at least 'reveal' mode, for policy management."
            end
            []
          end.each do |grant|
            yield grant
          end
        end

        # Validate that all the requested roles exist.
        def validate!
          requested.to_a.flatten.uniq.each do |roleid|
            validate_role_exists! roleid
          end
        end

        # Add a Types::Grant to the set of requested grants.
        def add_requested_grant grant
          Array(grant.roles).each do |role|
            Array(grant.members).each do |member|
              requested.add [ role.roleid, member.role.roleid ]
              requested_with_admin_flag.add [ role.roleid, member.role.roleid, !!member.admin ]
            end
          end
        end

        # Removes a Types::Revoke from the set of requested grants.
        def remove_revoked_grant revoke
          Array(revoke.roles).each do |role|
            Array(revoke.members).each do |member|
              requested.delete [ role.roleid, member.roleid ]
              requested_with_admin_flag.delete [ role.roleid, member.roleid, true ]
              requested_with_admin_flag.delete [ role.roleid, member.roleid, false ]
            end
          end
        end
      
        # Add a Conjur::API::Rolerevoke that is already held.
        def add_existing_grant role, grant
          existing.add [ role.roleid, grant.member.roleid ]
          existing_with_admin_flag.add [ role.roleid, grant.member.roleid, grant.admin_option ]
        end
      end
      
      # Privilege grants are [ roleid, privilege, resourceid, grant_option ].
      class PrivilegeFacts < BaseFacts
        
        # Enumerate all existing permissions for the specified +resource+.
        # Only permissions that apply the specified +privilege+ are considered.
        # Each permission is yielded to the block.
        def resource_permissions resource, privileges, &block
          permissions = begin
            resource = JSON.parse(api.resource(resource.resourceid).get)
            # Malformed resource ids can be interpreted as a resource search
            if resource.is_a?(Array)
              []
            else 
              resource['permissions']
            end
          rescue RestClient::ResourceNotFound
            if api.resource(resource.resourceid).exists?
              $stderr.puts "WARNING: Unable to fetch permissions of resource #{resource.resourceid}. Use 'elevate' mode, or at least 'reveal' mode, for policy management."
            end
            []
          end
          permissions.select{|p| privileges.member?(p['privilege'])}.each do |permission|
            yield permission
          end
        end
        
        # Validate that all the requested roles exist.
        def validate!
          requested.to_a.map{|row| row[0]}.uniq.each do |roleid|
            validate_role_exists! roleid
          end
          requested.to_a.map{|row| row[2]}.uniq.each do |resourceid|
            validate_resource_exists! resourceid
          end
        end
        
        # Add a Types::deny to the set of requested grants.
        def add_requested_permission permit
          Array(permit.roles).each do |member|
            Array(permit.privileges).each do |privilege|
              Array(permit.resources).each do |resource|
                requested.add [ member.role.roleid, privilege, resource.resourceid ]
                requested_with_admin_flag.add [ member.role.roleid, privilege, resource.resourceid, !!member.admin ]
              end
            end
          end
        end

        # Removes a Types::Deny from the set of requested grants.
        def remove_revoked_permission deny
          Array(deny.roles).each do |role|
            Array(deny.privileges).each do |privilege|
              Array(deny.resources).each do |resource|
                requested.delete [ role.roleid, privilege, resource.resourceid ]
                requested_with_admin_flag.delete [ role.roleid, privilege, resource.resourceid, true ]
                requested_with_admin_flag.delete [ role.roleid, privilege, resource.resourceid, false ]
              end
            end
          end
        end
      
        # Add a permission that is already held.
        def add_existing_permission permission
          existing.add [ permission['role'], permission['privilege'], permission['resource'] ]
          existing_with_admin_flag.add [ permission['role'], permission['privilege'], permission['resource'], permission['grant_option'] ]
        end
      end
    end
  end
end