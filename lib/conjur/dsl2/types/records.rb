module Conjur
  module DSL2
    module Types
      module ActsAsResource
        def self.included(base)
          base.module_eval do
            attribute :id,   kind: :string, singular: true, dsl_accessor: true
            attribute :account, kind: :string, singular: true
            attribute :owner, kind: :role, singular: true, dsl_accessor: true
            
            attribute :annotations, kind: :hash, type: OpenStruct, singular: true
            
            def description value
              annotation 'description', value
            end
            
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
          [ account || default_account, resource_kind, id ].join(":")
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
          [ account || default_account, role_kind, id ].join(":")
        end
        
        def role?
          true
        end
        
        def role_kind
          self.class.name.split("::")[-1].underscore
        end
        
        def role_id
          id
        end
      end
      
      class Role < Base
        include ActsAsRole
        
        attribute :id,   kind: :string, singular: true, dsl_accessor: true
        attribute :kind, kind: :string, singular: true, dsl_accessor: true
        attribute :account, kind: :string, singular: true
        attribute :owner, kind: :role, singular: true, dsl_accessor: true
        
        def initialize kind = nil, id = nil
          self.kind = kind if kind
          self.id = id if id
        end

        def roleid default_account
          [ account || default_account, kind, id ].join(":")
        end
        
        def role_id; id; end
        def role_kind; kind; end
                  
        def immutable_attribute_names
          []
        end
      end
      
      class Resource < Base
        include ActsAsResource

        attribute :kind, kind: :string, singular: true, dsl_accessor: true
        
        def initialize kind = nil, id = nil
          self.kind = kind if kind
          self.id = id if id
        end
        
        def resource_kind
          kind
        end
      end
      
      class User < Base
        include ActsAsResource
        include ActsAsRole
        
        attribute :uidnumber, kind: :integer, singular: true, dsl_accessor: true
        
        def id_attribute; 'login'; end
        
        def custom_attribute_names
          [ :uidnumber ]
        end
      end
      
      class Group < Base
        include ActsAsResource
        include ActsAsRole
        
        attribute :gidnumber, kind: :integer, singular: true, dsl_accessor: true
        
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
        
        attribute :kind,      kind: :string, singular: true, dsl_accessor: true
        attribute :mime_type, kind: :string, singular: true, dsl_accessor: true
        
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
