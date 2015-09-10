module Conjur
  module DSL2
    module Types
      module ActsAsResource
        def self.included(base)
          base.module_eval do
            attribute :id, kind: :string, singular: true
            
            attribute :annotations, kind: :hash, type: OpenStruct, singular: true
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
        
        attribute :kind, kind: :string, singular: true
        attribute :id,   kind: :string, singular: true
      end
      
      class Resource < Base
        include ActsAsResource

        attribute :kind, kind: :string, singular: true
        attribute :id,   kind: :string, singular: true
      end
      
      class User < Base
        include ActsAsResource
        include ActsAsRole
      end
      
      class Group < Base
        include ActsAsResource
        include ActsAsRole
      end
      
      class Host < Base
        include ActsAsResource
        include ActsAsRole
      end
      
      class Layer < Base
        include ActsAsResource
        include ActsAsRole
      end
      
      # Manage the 'use' internal role on a layer.
      class LayerUse < Base
        include ActsAsRole
        
        attribute :id,   kind: :string, singular: true
      end
      
      # Manage the 'admin' internal role on a layer.
      class LayerAdmin < Base
        include ActsAsRole
        
        attribute :id,   kind: :string, singular: true
      end
      
      class Variable < Base
        include ActsAsResource
        
        attribute :kind,      kind: :string, singular: true
        attribute :mime_type, kind: :string, singular: true
      end
      
      class Webservice < Base
        include ActsAsResource
      end
    end
  end
end
