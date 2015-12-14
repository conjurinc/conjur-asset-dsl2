module Conjur::DSL2
  module Executor
    class Base
      attr_reader :statement, :actions
      
      def initialize statement, actions
        @statement = statement
        @actions = actions
      end
      
      def action obj
        @actions.push obj
      end
    end
  end
end
