module Conjur
  module DSL2
    module Types
      class Member < Base
        def initialize role = nil
          self.role = role if role
        end
        
        roles   :role
        boolean :admin

        register_yaml_type 'member'
      end
    end
  end
end
