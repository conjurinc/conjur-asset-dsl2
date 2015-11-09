require 'conjur-asset-dsl2'
require 'conjur/dsl2/executors/base'

module Conjur
  module DSL2
    module Executors
      module ChangeOwnerAction
        def change_owner
          return [] unless resource? && record.owner

          if resource.owner != record.owner.roleid(default_account)
            [ "PUT", resource_path, { "ownerid" => record.owner.roleid } ]
          else
            []
          end
        end
      end
      
      module UpdateAnnotationsAction
        def update_annotations
          return unless resource?
          
          (record.annotations||{}).keys.inject([]) do |memo, attr|
            existing_value = resource.annotations[attr]
            new_value = record.annotations[attr]
            if new_value != existing_value
              memo.push [ "PUT", update_annotation_path, { "name" => attr.to_s, "value" => new_value }]
            end
            memo
          end
        end

        def update_annotation_path
          [ "authz", account, "annotations", record.resource_kind, record.id ].join('/')
        end
      end
      
      class Resource < BaseExecutor
        include ChangeOwnerAction
        include UpdateAnnotationsAction
        
        def create
          if resource.exists?
            change_owner +
              update_annotations
          else
            [ [ "PUT", create_path, create_parameters ] ] + update_annotations
          end
        end
        
        def resource?; true; end
        def resource; resource; end
        
        def resource
          api.resource([ account, resource_kind, resource_id ].join(':'))
        end
        
        def resource_path
          [ "authz", account, "resources", resource_kind, resource_id ].join('/')
        end
      end
      
      class Record < BaseExecutor
        include ChangeOwnerAction
        include UpdateAnnotationsAction
        
        def create
          if object.exists?
            change_owner + 
              update_attributes + 
              update_annotations
          else
            [ [ "POST", create_path, create_parameters ] ] + update_annotations
          end
        end
        
        def resource?; record.resource?; end

        def resource; api.resource([ account, record.resource_kind, record.id ].join(":")); end
          
        def update_attributes
          record.custom_attribute_names.inject([]) do |memo, attr|
            existing_value = object.send(attr)
            new_value = record.send(attr)
            if new_value && new_value != existing_value
              raise "Cannot modify immutable attribute '#{record.resource_kind}.#{attr}'" if record.immutable_attribute_names.member?(attr)
              memo.push [ "PUT", update_path, { attr.to_s => new_value || "" }]
            end
            memo
          end
        end
        
        def create_parameters
          {
            "id" => record.id
          }.tap do |params|
            custom_attrs = record.custom_attribute_names.inject({}) do |memo, attr|
              value = record.send(attr)
              memo[attr.to_s] = value if value
              memo
            end
            params.merge! custom_attrs
            params["ownerid"] = record.owner.roleid if record.owner
          end
        end
        
        def create_path
          [ kind_path ].join('/')
        end

        def update_path
          require 'cgi'
          [ kind_path, CGI.escape(record.id) ].join('/')
        end
        
        def kind_path
          record.resource_kind.pluralize
        end
        
        def object
          @object ||= api.send(record.resource_kind, record.id)
        end
      end
    end
  end
end
