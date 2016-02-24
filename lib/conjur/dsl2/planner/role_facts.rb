module Conjur
  module DSL2
    module Planner
      class RoleFacts
        attr_accessor :planner, :existing_grants, :requested_grants, :existing_grants_with_admin_flag, :requested_grants_with_admin_flag
        
        def initialize planner
          @planner = planner
          @requested_grants = Set.new
          @requested_grants_with_admin_flag = Set.new
          @existing_grants  = Set.new
          @existing_grants_with_admin_flag  = Set.new
        end

        # Validate that all the requested roles exist.
        def validate!
          requested_grants.to_a.flatten.uniq.each do |roleid|
            validate_role_exists! roleid
          end
        end
        
        # Return the set of [ roleid, admin_option ] grants which are requested but not already held.
        #
        # Note that if a grant is held with a different +admin_option+ flag than requested,
        # re-granting the role with the new admin option will update the role grant and create
        # the desired state.
        #
        # @return Array of [ roleid, admin ]
        def grants_to_apply
          requested_grants_with_admin_flag - existing_grants_with_admin_flag
        end
        
        # Return the set of +roleid+ which are held but not requested.
        #
        # The admin flag is ignored by this method. So, if a role is held (with or without
        # admin), and it is not requested (with or without admin), it is revoked. The
        # case in which the role is held with a different admin option than requested
        # is handled by +grants_to_apply+.
        #
        # @return Set roleid
        def grants_to_revoke
          existing_grants - requested_grants
        end

        # Add a Types::Grant that is requested.
        def add_requested_grant grant
          Array(grant.roles).each do |role|
            Array(grant.members).each do |member|
              requested_grants.add [ role.roleid, member.role.roleid ]
              requested_grants_with_admin_flag.add [ role.roleid, member.role.roleid, !!member.admin ]
            end
          end
        end
      
        # Add a Conjur::API::RoleGrant that is already held.
        def add_existing_grant grant
          existing_grants.add [ grant.role.roleid, grant.member.roleid ]
          existing_grants_with_admin_flag.add [ grant.role.roleid, grant.member.roleid, grant.admin_option ]
        end
        
        def validate_role_exists! role
          error("role not found: #{role.roleid} in #{planner.plan.roles_created.to_a}") unless planner.role_exists?(role)
        end
      end
    end
  end
end