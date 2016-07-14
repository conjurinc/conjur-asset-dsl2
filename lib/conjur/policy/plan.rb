module Conjur
  module Policy
    class Plan
      attr_reader :actions, :roles_created, :resources_created

      def initialize(existing_resources, current_role_graph)
        @actions = []
        @roles_created = Set.new
        @resources_created = Set.new
        @existing_resources = Set.new(existing_resources.collect(&:resourceid))
        @current_role_graph = current_role_graph
        @existing_roles = current_role_graph.inject(Set.new) {|roles, edge| roles.add(edge.parent).add(edge.child)}
      end
      
      def action a
        @actions.push a
      end

      def role_exists?(id)
        @existing_roles.include?(id)
      end

      def resource_exists?(id)
        @existing_resources.include?(id)
      end

      # return true or false if the role with admin_id has adminship
      # on role, nil if it can't be determined from the role graph
      # (e.g. because the role graph was created by an old server).
      def can_admin_role?(admin_id, role)
        return nil if @current_role_graph.first.admin_option.nil?

        @current_role_graph.any? {|e| e.parent == role.roleid && e.child == admin_id && e.admin_option }
      end

    end
  end
end
