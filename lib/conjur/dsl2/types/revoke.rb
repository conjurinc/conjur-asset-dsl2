module Conjur
  module DSL2
    module Types
      class Revoke < Base
        attribute :role, dsl_accessor: true
        attribute :member, kind: :role, dsl_accessor: true
        
        include RoleMemberDSL
        
        def to_s
          "Revoke #{role} from #{member}"
        end
      end
    end
  end
end
