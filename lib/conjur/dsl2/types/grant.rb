module Conjur
  module DSL2
    module Types
      class Grant < Base
        attribute :role, dsl_accessor: true
        attribute :member
        attribute :replace, kind: :boolean, singular: true, dsl_accessor: true
        
        include RoleMemberDSL
        include ManagedRoleDSL
        
        def to_s
          "Grant #{role} to #{member.role}#{member.admin ? ' with admin option' : ''}"
        end
      end
    end
  end
end
