require 'conjur/dsl2/planner/base'

module Conjur
  module DSL2
    module Planner
      module ChangeOwnerAction
        def change_owner plan
          return unless resource? && record.owner

          if resource.owner != record.owner.roleid(default_account)
            plan.action [ "PUT", resource_path, { "ownerid" => record.owner.roleid } ]
          end
        end
      end
      
      module UpdateAnnotationsAction
        def update_annotations plan
          return unless resource?
          
          existing = resource.exists? ? resource.annotations : {}
          (record.annotations||{}).keys.each do |attr|
            existing_value = existing[attr]
            new_value = record.annotations[attr]
            if new_value != existing_value
              plan.action [ "PUT", update_annotation_path, { "name" => attr.to_s, "value" => new_value }]
            end
          end
        end

        def update_annotation_path
          [ "authz", account, "annotations", record.resource_kind, record.id ].join('/')
        end
      end
      
      class Role < Base
        def plan plan
          if role.exists?
            # TODO: change_owner
          else
            plan.action [ "PUT", role_path, create_parameters ]
          end
        end
        
        def role?; true; end
        def role_kind; record.role_kind; end
        def role_id; record.id; end
        
        def role
          api.role([ account, role_kind, role_id ].join(':'))
        end
        
        def role_path
          [ "authz", account, "roles", role_kind, role_id ].join('/')
        end
        
        def create_parameters
          {}.tap do |params|
            params["acting_as"] = record.owner.roleid if record.owner
          end
        end
      end
      
      class Resource < Base
        include ChangeOwnerAction
        include UpdateAnnotationsAction
        
        def plan plan
          if resource.exists?
            change_owner(plan)
            update_annotations(plan)
          else
            plan.action [ "PUT", resource_path, create_parameters ]
            update_annotations(plan)
          end
        end
        
        def resource?; true; end
        def resource_kind; record.resource_kind; end
        def resource_id; record.id; end
        
        def resource
          api.resource([ account, resource_kind, resource_id ].join(':'))
        end
        
        def resource_path
          [ "authz", account, "resources", resource_kind, resource_id ].join('/')
        end
        
        def create_parameters
          {}.tap do |params|
            params["acting_as"] = record.owner.roleid(default_account) if record.owner
          end
        end
      end
      
      class Webservice < Resource
      end

      class Policy < Base
        def plan plan
          Role.new(record, api).plan(plan)
          record.owner = Conjur::DSL2::Types::Role.new "policy", record.id
          record.owner.account = record.account
          Resource.new(record, api).plan(plan)
          record.body.each do |record|
            Planner.planner_for(record, api).plan(plan)
          end
        end
      end
      
      class Record < Base
        include ChangeOwnerAction
        include UpdateAnnotationsAction
        
        def plan plan
          if object.exists?
            change_owner plan 
            update_attributes plan
          else
            plan.action [ "POST", create_path, create_parameters ]
          end
          update_annotations plan
        end
        
        def resource?; record.resource?; end

        def resource; api.resource([ account, record.resource_kind, record.id ].join(":")); end
          
        def update_attributes plan
          record.custom_attribute_names.each do |attr|
            existing_value = object.send(attr)
            new_value = record.send(attr)
            if new_value && new_value != existing_value
              raise "Cannot modify immutable attribute '#{record.resource_kind}.#{attr}'" if record.immutable_attribute_names.member?(attr)
              plan.action [ "PUT", update_path, { attr.to_s => new_value || "" }]
            end
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
