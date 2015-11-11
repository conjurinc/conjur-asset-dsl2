module Conjur
  module DSL2
    class Plan
      attr_reader :actions
      
      def initialize
        @actions = []
      end
      
      def action a
        @actions.push a
      end
    end
  end
end