module Conjur
  module DSL2
    module Types
      class Permissions < Base
        register_yaml_type 'permissions'
        
        resources :resources
        resource  :resource
        strings   :privilege
        member    :member
        members   :members
      end
    end
  end
end
