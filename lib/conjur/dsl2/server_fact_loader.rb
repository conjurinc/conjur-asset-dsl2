require 'conjur/dsl2/facts/base'
module Conjur::DSL2
  # Atrocious name, this class is responsible for fetching a permissions model from
  # Conjur.
  class ServerFactLoader
    include Conjur::DSL2::Facts::Helper

    IGNORED_ROLE_IDS = %w(!:!:root)

    attr_reader :api
    attr_reader :acting_as
    attr_reader :namespace

    # options are `:acting_as` and `:namespace`.  Requests will
    # be performed as a role given by `:acting_as`, and only resources
    # and roles with prefix `:namespace` will be considered.
    def initialize api, opts={}
      @api = api
      @acting_as = opts[:acting_as]
      @namespace = opts[:namespace]
    end

    def facts
      @facts ||= build_facts
    end

    private

    # Get all roles and resources.  We first list resources (visible to the role),
    # then roles (via role graph).  We match the roles to resources to generate
    # `RoleExists` facts, and use the memberships implicit in the role graph to
    # create `HasRole` facts. Finally, we use the `permissions` field of each
    # resource to create `HasPermission` facts.
    def build_facts
      @facts = Conjur::DSL2::Facts::FactSet.new

      add_record_facts
      add_membership_facts
      add_permission_facts

      @facts
    end



    def add_record_facts
      resources.each do |res|
        @facts << create_record_exists(res.kind, res.identifier, res.owner)
      end
    end

    def add_membership_facts
      grants.each do |role_id, members|
        members.each do |grant|
          @facts << create_grant(role_id, grant.member.role_id, grant.admin_option)
        end
      end
    end

    def add_permission_facts
      resource_permissions.each do |res_id, permission|
        @facts << create_permit(res_id, permission['role'], permission['privilege'], permission['grant_option'])
      end
    end

    def resource_permissions
      @resource_permissions ||= [].tap do |ary|
        resources.each do |res|
          res.attributes['permissions'].each do |p|
            ary << [res.resource_id, p]
          end
        end
      end
    end

    def resources
      @resources ||= fetch_resources
    end

    def roles
      @roles ||= fetch_roles
    end

    def roles_by_id
      @roles_by_id ||= roles.inject({}) do |hash, role|
        hash[role] = api.role(role); hash
      end
    end

    def fetch_resources
      opts = acting_as ? {acting_as: acting_as} : {}
      api.resources(opts).tap do |resources|
        resources.select! { |r| r.identifier.start_with?(namespace) } if namespace
      end
    end

    def fetch_roles
      role_graph.inject(Set.new) do |set,edge|
        set << edge.parent << edge.child
      end.to_a
    end

    def role_graph
      @role_graph ||= begin
        api.role_graph(acting_as || api.current_role, ancestors: true, descendants: true)
      end
    end

    def grants
      @grants ||= build_grants
    end

    def build_grants
      Hash.new{ |h,k| h[k] = [] }.tap do |map|
        roles.each do |role_id|
          api.role(role_id).members.each do |grant|
            map[role_id] << grant
          end
        end
      end
    end
  end
end