module Conjur
  module DSL2
    module Types
      class Permit < Base
        register_yaml_type 'permit'
        
        resources :resource
        strings   :privilege
        members   :member
      end
    end
  end
end
