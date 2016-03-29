module Conjur::Policy::Types
  class Deny < Base

    self.description = %(
Deny privileges on a [Resource](#reference/resource). (compare:
[Revoke](#reference/revoke) for [Roles](#reference/role))
)

    self.example = %(
- !variable secret
- !user rando
- !deny
    role: !user rando
    privilege: read
    resource: !variable secret
)

    attribute :role, kind: :role, dsl_accessor: true
    attribute :privilege, kind: :string, dsl_accessor: true
    attribute :resource, dsl_accessor: true
        
    include ResourceMemberDSL

    def to_s
      "Deny #{role} to '#{privilege}' #{resource}"
    end
  end
end
