module Conjur
  module DSL2
    module Types
      class Deny < Base
        register_yaml_type 'deny'
        
        resources :resource
        strings   :privilege
        members   :member
      end
    end
  end
end
