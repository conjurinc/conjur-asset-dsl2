module Conjur::DSL2::Types
  class Member < Base
    def initialize role = nil
      self.role = role
    end

    attribute :role
    attribute :admin, kind: :boolean, singular: true

    self.description = 'Describe a member of a Role.'

    self.example = %(
- !user dee
- !user dum
- !group brothers

- !grant
  role: !group brothers
  members:
  - !user dee
  - !member dum
      role: !user dum
      admin: true
)

    def to_s
      "#{role} #{admin ? 'with' : 'without'} admin option"
    end
  end
end
