module Conjur
  module DSL2
    module Types
      class Deny < Base
        attribute :role, kind: :role, dsl_accessor: true
        attribute :privilege, kind: :string, dsl_accessor: true
        attribute :resource, dsl_accessor: true
        
        include ResourceMemberDSL
        
        def to_s
          "Deny #{role} to '#{privilege}' #{resource}"
        end
      end
    end
  end
end
