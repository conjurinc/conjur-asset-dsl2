module Conjur
  module DSL2
    class Plan
      attr_reader :actions, :policy
      attr_accessor :namespace, :ownerid
      
      def initialize namespace = nil
        @namespace = namespace
        @actions = []
        @policy = nil
      end
      
      def scoped_id id
        id = id.id if id.respond_to?(:id)
        if id[0] == '/'
          id[1..-1]
        else
          tokens = []
          tokens.push @namespace if @namespace
          tokens.push @policy.id if @policy
          tokens.push id
          tokens.join('/')
        end
      end
      
      def policy= policy
        raise "Plan policy is already specified" if @policy && policy
        @policy = policy
      end
      
      def action a
        @actions.push a
      end
    end
  end
end
