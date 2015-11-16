module Conjur::DSL2
  # Atrocious name, this class is responsible for fetching a permissions model from
  # Conjur.
  class ServerFactLoader
    include Conjur::DSL2::Facts::Helper

    attr_reader :api

    # API must already be scoped
    def initialize api, acting_as=nil
      @api = api
      @acting_as = acting_as
    end

    # Get all roles and resources.  We first list resources (visible to the role),
    # then roles (via role graph).  We match the roles to resources to generate
    # `RoleExists` facts, and use the memberships implicit in the role graph to
    # create `HasRole` facts. Finally, we use the `permissions` field of each
    # resource to create `HasPermission` facts.
    def fetch
      @facts = Conjur::DSL2::Facts::FactSet.new

      add_record_facts
      add_membership_facts
      add_permission_facts

      @facts
    end

    private

    def add_record_facts
      records.each do |rec|
        @facts << create_record_exists(rec['kind'], rec['id'], rec['owner'])
      end
    end

    def add_membership_facts
      roles_with_members.each do |role_id, member_id|
        @facts << create_has_role(role_id, member_id)
      end
    end

    def add_permission_facts
      resource_permissions.each do |res_id, permission|
        @facts << create_permitted(res_id, permission['role'], permission['privilege'], permission['grant_option'])
      end
    end

    # Return
    def records

    end

    def resources
      @resources ||= fetch_resources
    end

    def roles
      @roles ||= fetch_roles
    end

    def roles_by_id
      @roles_by_id ||= roles.inject({}) do |hash, role|
        hash[role.id] = role; hash
      end
    end

    def fetch_resources
      opts = @acting_as ? {acting_as: @acting_as} : {}
      api.resources(opts)
    end

    def fetch_roles
      # TODO
    end
  end
end