module Conjur
  module DSL2
    module Types
      class Permit < Base
        attribute :role, kind: :member
        attribute :privilege, kind: :string, dsl_accessor: true
        attribute :resource, dsl_accessor: true
        attribute :replace, kind: :boolean, singular: true, dsl_accessor: true
        
        include ResourceMemberDSL
        
        def initialize privilege = nil
          self.privilege = privilege
        end
        
        def to_s
          "Permit #{role.role} to '#{privilege}' #{resource}#{role.admin ? ' with grant option' : ''}"
        end
      end
    end
  end
end
