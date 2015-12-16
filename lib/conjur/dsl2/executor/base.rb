module Conjur::DSL2
  module Executor
    class Base
      attr_reader :statement, :actions, :default_account
      
      def initialize statement, actions, default_account
        @statement = statement
        @actions = actions
        @default_account = default_account
      end
      
      def action obj
        @actions.push obj
      end
    end
  end
end
