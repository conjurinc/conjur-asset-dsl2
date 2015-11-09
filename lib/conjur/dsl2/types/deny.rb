module Conjur
  module DSL2
    module Types
      class Deny < Base
        attribute :role, kind: :member
        attribute :privilege, kind: :string, dsl_accessor: true
        attribute :resource, dsl_accessor: true
        
        include ResourceMemberDSL
      end
    end
  end
end
