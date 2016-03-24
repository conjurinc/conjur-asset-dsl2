module Conjur
  module DSL2
    module Types
      class Permit < Base
        attribute :role, kind: :member
        attribute :privilege, kind: :string, dsl_accessor: true
        attribute :resource, dsl_accessor: true
        attribute :replace, kind: :boolean, singular: true, dsl_accessor: true

        self.description = %(
Allow a role to have permissions on a resource. (compare: Deny)

[More](/key_concepts/rbac.html) on role-based access control in Conjur.
)

        self.example = %(
!variable answer
!user deep_thought

!permit
  role: !user deep_thought
  privileges: [ read, execute, update ]
  resource: !variable answer
)
        
        include ResourceMemberDSL
        
        def initialize privilege = nil
          self.privilege = privilege
        end
        
        def to_s
          if Array === role
            role_string = role.map &:role
            admin = false
          else
            role_string = role.role
            admin = role.admin
          end
          "Permit #{role_string} to [#{Array(privilege).join(', ')}] on #{Array(resource).join(', ')}#{admin ? ' with grant option' : ''}"
        end
      end
    end
  end
end
