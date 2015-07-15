module Conjur
  module DSL2
    module Types
      module ActsAsResource
        def self.included(base)
          base.module_eval do
            attr_accessor :id
            attr_accessor :annotations
            
            register_yaml_field 'annotations', Hash
          end
        end
        
        def resource?
          true
        end
      end
      
      module ActsAsRole
        def role?
          true
        end
      end
      
      class Role < Base
        include ActsAsRole
        
        string :kind
        string :id
        
        register_yaml_type 'role'
      end
      
      class Resource < Base
        include ActsAsResource

        string :kind
        string :id
        
        register_yaml_type 'resource'
      end
      
      class User < Base
        include ActsAsResource
        include ActsAsRole
        
        register_yaml_type 'user'
      end
      
      class Group < Base
        include ActsAsResource
        include ActsAsRole

        register_yaml_type 'group'
      end
      
      class Host < Base
        include ActsAsResource
        include ActsAsRole
        
        register_yaml_type 'host'
      end
      
      class Layer < Base
        include ActsAsResource
        include ActsAsRole
        
        register_yaml_type 'layer'
      end
      
      class Variable < Base
        include ActsAsResource
        
        register_yaml_type 'variable'
      end
      
      class Webservice < Base
        include ActsAsResource

        register_yaml_type 'webservice'
      end
    end
  end
end
