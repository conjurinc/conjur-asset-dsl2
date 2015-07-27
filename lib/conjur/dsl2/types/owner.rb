module Conjur
  module DSL2
    module Types
      class Owner < Base
        attribute :record, kind: :resource
        attribute :owner, singular: true, kind: :role
      end
    end
  end
end

