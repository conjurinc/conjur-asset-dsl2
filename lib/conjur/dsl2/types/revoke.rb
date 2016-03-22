module Conjur
  module DSL2
    module Types
      class Revoke < Base
        attribute :role, dsl_accessor: true
        attribute :member, kind: :role, dsl_accessor: true

        self.description = %(
Remove a role grant. (contrast: Grant)

[More](/key_concepts/rbac.html) on role-based access control in Conjur.
)

        self.example = %(
!revoke
  role: !group soup_eaters
  member: !user you
)

        def to_s
          "Revoke #{role} from #{member}"
        end
      end
    end
  end
end
