module Conjur
  module Policy
    module Types
      class Permit < Base
        attribute :role, kind: :member
        attribute :privilege, kind: :string, dsl_accessor: true
        attribute :resource, dsl_accessor: true
        attribute :replace, kind: :boolean, singular: true, dsl_accessor: true

        self.description = %(
Give permissions on a [Resource](#reference/resource) to a [Role](#reference/role). (contrast: [Deny](#reference/deny))

The permissions are:
1. read (see the resource)
2. execute (use the resource)
3. update (make changes to the resource)

[More](/key_concepts/rbac.html) on role-based access control in Conjur.
)

        self.example = %(
- !variable answer
- !user deep_thought

- !permit
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
