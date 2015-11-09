module Conjur
  module DSL2
    module Types
      module ActsAsResource
        def self.included(base)
          base.module_eval do
            attribute :id, kind: :string, singular: true
            attribute :account, kind: :string, singular: true
            attribute :owner, kind: :role, singular: true
            
            attribute :annotations, kind: :hash, type: OpenStruct, singular: true
            
            def annotation name, value
              self.annotations ||= OpenStruct.new
              self.annotations[name] = value
            end
          end
        end
        
        def initialize id = nil
          self.id = id if id
        end

        def resourceid default_account
          [ account || default_account, kind, id ].join(":")
        end
        
        def resource_kind
          self.class.name.split("::")[-1].underscore
        end

        def resource_id
          id
        end
        
        def action
          :create
        end
        
        def resource?
          true
        end
        
        def immutable_attribute_names
          []
        end
      end
      
      module ActsAsRole
        def roleid default_account
          [ account || default_account, kind, id ].join(":")
        end
        
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
        
        attribute :uidnumber, kind: :integer, singular: true
        
        def custom_attribute_names
          [ :uidnumber ]
        end
      end
      
      class Group < Base
        include ActsAsResource
        include ActsAsRole
        
        attribute :gidnumber, kind: :integer, singular: true
        
        alias gidnumber_accessor gidnumber

        def gidnumber v = nil
          if v
            self.gidnumber = v
          else
            gidnumber_accessor
          end
        end

        def custom_attribute_names
          [ :gidnumber ]
        end
      end
      
      class Host < Base
        include ActsAsResource
        include ActsAsRole
      end
      
      class Layer < Base
        include ActsAsResource
        include ActsAsRole
      end
      
      class Variable < Base
        include ActsAsResource
        
        attribute :kind,      kind: :string, singular: true
        attribute :mime_type, kind: :string, singular: true
        
        alias kind_accessor kind
        alias mime_type_accessor mime_type

        def kind v = nil
          if v
            self.kind = v
          else
            kind_accessor
          end
        end

        def mime_type v = nil
          if v
            self.mime_type = v
          else
            mime_type_accessor
          end
        end

        def custom_attribute_names
          [ :kind, :mime_type ]
        end
        
        def immutable_attribute_names
          [ :kind, :mime_type ]
        end
      end
      
      class Webservice < Base
        include ActsAsResource
      end
      
      class ManagedRole < Base
        include ActsAsRole
        
        def initialize record = nil, role_name = nil
          self.record = record if record
          self.role_name = role_name if role_name
        end
        
        attribute :record,    kind: :role,   singular: true
        attribute :role_name, kind: :string, singular: true
      end
    end
  end
end
