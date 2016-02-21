module Conjur
  module DSL2
    # * Makes all ids absolute, by prepending the namespace (if any) and the enclosing policy (if any).
    # * Flattens and sorts records which are contained in a YAML list. For example, a policy may define
    # a list of variables in a named list.
    #
    class Resolver
      attr_reader :ownerid, :namespace
      
      # +ownerid+ is required. Any records without an owner will be assigned this owner. The exception
      # is records defined in a policy, which are always owned by the policy role unless an explicit owner
      # is indicated (which would be rare).
      # +namespace+ is optional. It's prepended to the id of every record, except for ids which begin
      # with a '/' character.
      def initialize ownerid, namespace = nil
        @ownerid   = ownerid
        @namespace = namespace
      end
      
      # Loop through all records, apply the resolve algorithm to them.
      def resolve records
        traverse records, Set.new, method(:resolve_id), method(:on_resolve_policy_id)
      end
      
      def resolve_id record
        return unless record.respond_to?(:id)
        
        id = record.id
        if id.blank?
          raise "#{record.to_s} has no id, and no namespace is available to populate it" unless namespace
          record.id = namespace
        elsif id[0] == '/'
          record.id = id[1..-1]
        else
          record.id = [ namespace, id ].compact.join('/')
        end
      end
      
      def on_resolve_policy_id policy, visited
        saved_namespace = @namespace
        @namespace = policy.id
        traverse policy.body, visited, method(:resolve_id), method(:on_resolve_policy_id)
      ensure
        @namespace = saved_namespace
      end
      
      protected
      
      # Traverse an Array-ish of records, calling a +handler+ method for each one.
      # If a record is a Policy, then the +policy_handler+ is invoked, after the +handler+.
      def traverse records, visited, handler, policy_handler = nil
        Array(records).flatten.each do |record|
          next if visited.member?(record)
          visited.add record
          handler.call record
          traverse record.referenced_records, visited, handler, policy_handler
          policy_handler.call record, visited if policy_handler && record.is_a?(Types::Policy)
        end
      end
    end
  end
end
