module Conjur
  module Policy
    class Plan
      attr_reader :actions, :roles_created, :resources_created

      def initialize(existing_resources, current_role_graph)
        @actions = []
        @roles_created = Set.new
        @resources_created = Set.new
        @existing_resources = Set.new(existing_resources.collect(&:resourceid))
        # $stderr.puts "@existing_resources: #{@existing_resources.inspect}"
        @current_role_graph = current_role_graph
        @existing_roles = current_role_graph.inject(Set.new) {|roles, edge| roles.add(edge.parent).add(edge.child)}
        # $stderr.puts "existing roles: #{@existing_roles.inspect}"
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

    end
  end
end
