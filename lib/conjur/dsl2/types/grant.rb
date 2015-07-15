module Conjur
  module DSL2
    module Types
      class Grant < Base
        register_yaml_type 'grant'

        roles   :role
        members :member
      end
    end
  end
end

