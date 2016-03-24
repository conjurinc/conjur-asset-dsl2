module Conjur
  module DSL2
    module Types
      class Retire < Base
        attribute :record, kind: :resource

        self.description = %(
Move a Role or Resource to the attic, effectively deleting it (while
maintaining references to it in the audit log.)
)

        self.example = %(
!retire
  record: !user DoubleOhSeven
)

        def to_s
          "Retire #{record}"
        end
      end
    end
  end
end

