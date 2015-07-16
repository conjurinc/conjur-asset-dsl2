module Conjur
  module DSL2
    module Types
      class Permissions < Base
        attribute :resource
        attribute :privilege, kind: :string
        attribute :member
      end
    end
  end
end
