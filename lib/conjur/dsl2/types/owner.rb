module Conjur
  module DSL2
    module Types
      class Owner < Base
        attribute :record, kind: :resource
        attribute :role, singular: true
      end
    end
  end
end

