module Conjur::DSL2::Types
  class Give < Base
    attribute :resource, kind: :resource
    attribute :owner, kind: :role

    self.description = %(
Give a resource to a role. (compare: Grant)

[More](/key_concepts/rbac.html) on role-based access control in Conjur.
)

    self.example = %(
- !user Link
- !secret song-of-storms

- !give
    resource: !secret song-of-storms
    owner: !user Link
)

    def to_s
      "Give #{resource} to #{owner}"
    end
  end
end
