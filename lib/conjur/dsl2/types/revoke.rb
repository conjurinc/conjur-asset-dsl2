module Conjur
  module DSL2
    module Types
      class Revoke < Base
        register_yaml_type 'revoke'

        role   :role
        member :member
      end
    end
  end
end

