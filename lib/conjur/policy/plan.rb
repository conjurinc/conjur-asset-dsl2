module Conjur
  module Policy
    class Plan
      attr_reader :actions, :roles_created, :resources_created
      
      def initialize
        @actions = []
        @roles_created = Set.new
        @resources_created = Set.new
      end
      
      def action a
        @actions.push a
      end
    end
  end
end
