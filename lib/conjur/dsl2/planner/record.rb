require 'conjur/dsl2/planner/base'

module Conjur
  module DSL2
    module Planner
      module ChangeOwnerAction
        def change_owner
          return unless resource? && record.owner

          if resource.owner != scoped_roleid(record.owner)
            action({
              'service' => 'authz',
              'type' => 'resource',
              'method' => 'put',
              'action' => 'change_owner',
              'id' => scoped_resourceid(record),
              'path' => resource_path,
              'parameters' => { "owner" => scoped_roleid(record.owner) },
              'description' => "Change owner of #{scoped_resourceid(record)} to #{scoped_roleid(record.owner)}"
            })
          end
        end
      end
      
      module UpdateAnnotationsAction
        def update_annotations
          return unless resource?
          
          existing = resource.exists? ? resource.annotations : {}
          (record.annotations||{}).keys.each do |attr|
            existing_value = existing[attr]
            new_value = record.annotations[attr]
            if new_value != existing_value
              action({
                'service' => 'authz',
                'type' => 'annotation',
                'action' => 'update',
                'id' => scoped_resourceid(record),
                'path' => update_annotation_path,
                'parameters' => { "name" => attr.to_s, "value" => new_value },
                'description' => "Update '#{attr}' annotation on #{scoped_resourceid(record)}"
              })
            end
          end
        end
        
        def update_annotation_path
          [ "authz", account, "annotations", record.resource_kind, record.id ].join('/')
        end
      end
      
      class Role < Base
        def do_plan
          if role.exists?
            # TODO: change_owner
          else
            action({
              'service' => 'authz',
              'type' => 'role',
              'action' => 'create',
              'method' => 'put',
              'path' => role_path,
              'id' => roleid,
              'parameters' => create_parameters,
              'description' => "Create role #{roleid}"
            })
          end
        end
        
        def role?; true; end
        def role_kind; record.role_kind; end
        def role_id; record.id; end
        def roleid; [ account, role_kind, scoped_id(role_id) ].join(':'); end
          
        def role
          api.role(roleid)
        end
        
        def role_path
          [ "authz", account, "roles", role_kind, scoped_id(role_id) ].join('/')
        end
        
        def create_parameters
          {}.tap do |params|
            params["acting_as"] = scoped_roleid(record.owner) if record.owner
          end
        end
      end
      
      class Resource < Base
        include ChangeOwnerAction
        include UpdateAnnotationsAction
        
        def do_plan
          if resource.exists?
            change_owner
            update_annotations
          else
            action({
              'service' => 'authz',
              'type' => 'resource',
              'action' => 'create',
              'method' => 'put',
              'id' => resourceid,
              'path' => resource_path,
              'parameters' => create_parameters,
              'description' => "Create resource #{resourceid}"
            })
            update_annotations
          end
        end
        
        def resource?; true; end
        def resource_kind; record.resource_kind; end
        def resource_id; record.id; end
        def resourceid; [ account, resource_kind, scoped_id(resource_id) ].join(':'); end
          
        def resource
          api.resource(resourceid)
        end
        
        def resource_path
          [ "authz", account, "resources", resource_kind, scoped_id(resource_id) ].join('/')
        end
        
        def create_parameters
          {}.tap do |params|
            params["acting_as"] = scoped_roleid(record.owner) if record.owner
          end
        end
      end
      
      class Webservice < Resource
      end

      class Policy < Base
        def do_plan
          Role.new(record, api).tap do |role|
            role.plan = plan
            role.do_plan
          end
          record.owner = Conjur::DSL2::Types::Role.new "policy", record.id
          record.owner.account = record.account
          Resource.new(record, api).tap do |resource|
            resource.plan = plan
            resource.do_plan
          end
          record.body.each do |record|
            plan.policy = self.record
            begin
              planner = Planner.planner_for(record, api)
              planner.plan = plan
              planner.do_plan
            ensure
              plan.policy = nil
            end
          end
        end
      end
      
      class Record < Base
        include ChangeOwnerAction
        include UpdateAnnotationsAction
        
        def do_plan
          if object.exists?
            change_owner
            update_attributes
          else
            action({
              'service' => 'directory',
              'type' => record.resource_kind,
              'action' => 'create',
              'path' => create_path,
              'parameters' => create_parameters,
              'description' => "Create #{record.resource_kind} #{scoped_id(record)}"
            })
          end
          update_annotations
        end
        
        def resource?; record.resource?; end

        def resource; api.resource([ account, record.resource_kind, scoped_id(record) ].join(":")); end
          
        def update_attributes
          record.custom_attribute_names.each do |attr|
            existing_value = object.attributes[attr]
            new_value = record.send(attr)
            if new_value && new_value != existing_value
              raise "Cannot modify immutable attribute '#{record.resource_kind}.#{attr}'" if record.immutable_attribute_names.member?(attr)
              action({ 
                'service' => 'directory', 
                'type' => record.resource_kind, 
                'action' => 'update',
                'path' => update_path,
                'id' => scoped_id(record), 
                'parameters' => { attr.to_s => new_value || "" },
                'description' => "Update '#{attr}' on #{record.resource_kind} #{scoped_id(record)}"
              })
            end
          end
        end
        
        def create_parameters
          {
            "id" => scoped_id(record)
          }.tap do |params|
            custom_attrs = record.custom_attribute_names.inject({}) do |memo, attr|
              value = record.send(attr)
              memo[attr.to_s] = value if value
              memo
            end
            params.merge! custom_attrs
            params["ownerid"] = scoped_roleid(record.owner.roleid) if record.owner
          end
        end
        
        def create_path
          [ kind_path ].join('/')
        end

        def update_path
          require 'cgi'
          [ kind_path, CGI.escape(scoped_id(record)) ].join('/')
        end
        
        def kind_path
          record.resource_kind.pluralize
        end
        
        def object
          @object ||= api.send(record.resource_kind, scoped_id(record))
        end
      end
      
      class Variable < Record
        def create_parameters
          super.tap do |params|
            params['mime_type'] ||= 'text/plain'
            params['kind'] ||= 'secret'
          end
        end
      end
    end
  end
end
