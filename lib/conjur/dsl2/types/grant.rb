module Conjur
  module DSL2
    module Types
      class Grant < Base
        attribute :role, dsl_accessor: true
        attribute :member
        attribute :exclusive, kind: :boolean, singular: true, dsl_accessor: true
        
        include RoleMemberDSL
      end
    end
  end
end
