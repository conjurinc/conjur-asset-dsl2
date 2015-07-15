module Conjur
  module DSL2
    module Types
      class Members < Base
        register_yaml_type 'members'
        
        roles   :role
        member  :member
        members :members
      end
    end
  end
end
