module Conjur
  module DSL2
    module Types
      class Revoke < Base
        attribute :role, dsl_accessor: true
        attribute :member
        
        include RoleMemberDSL
      end
    end
  end
end
