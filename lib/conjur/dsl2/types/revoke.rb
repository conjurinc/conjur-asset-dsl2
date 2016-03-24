module Conjur
  module DSL2
    module Types
      class Revoke < Base
        attribute :role, dsl_accessor: true
        attribute :member, kind: :role, dsl_accessor: true

        self.description = %(
Remove a [Role](#reference/role) grant. (contrast: [Grant](#reference/grant))

See also: [role-based access control guide](/key_concepts/rbac.html).
)

        self.example = %(
- !revoke
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
