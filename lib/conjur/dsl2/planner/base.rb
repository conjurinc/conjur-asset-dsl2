module Conjur
  module DSL2
    module Planner
      class Base
        include Conjur::DSL2::Logger

        attr_reader :record, :api
        attr_accessor :plan

        def initialize record, api
          raise "Expecting Conjur::DSL2::Types::Base, got #{record.class}" unless record.is_a?(Conjur::DSL2::Types::Base)
          @record = record
          @api = api
        end
        
        def action a
          @plan.action a
        end
                  
        def account
          record.account
        end
        
        def role_record fullid
          account, kind, id = fullid.split(':', 3)
          if kind == '@'
            Conjur::DSL2::Types::ManagedRole.build fullid
          else
            if record_class = record_type(kind)
              record_class.new.tap do |record|
                record.account = account
                unless record.is_a?(Conjur::DSL2::Types::Variable)
                  record.kind = kind if record.respond_to?(:kind=)
                end
                record.id = id
              end
            else
              Conjur::DSL2::Types::Role.new(fullid)
            end
          end
        end
        
        def record_type kind
          begin
            Conjur::DSL2::Types.const_get(kind.classify)
          rescue NameError
            nil
          end
        end
        
        alias resource_record role_record
        
        def resource
          api.resource(record.resourceid)
        end
        
        def role
          api.role(record.roleid)
        end

        def resource_exists? resource
          resource_id = resource.respond_to?(:resourceid) ? resource.resourceid : resource.to_s
          (plan.resources_created.include?(resource_id) ||  api.resource(resource_id).exists?)
        end

        def role_exists? role
          role_id = role.respond_to?(:roleid) ? role.roleid : role.to_s
          
          account, kind, id = role_id.split(':', 3)
          if kind == "@"
            # For managed role, check if the parent record will be created
            role_tokens = id.split('/')
            # This is the role_name
            role_tokens.pop
            role_kind = role_tokens.shift
            role_id = [ account, role_kind, role_tokens.join('/') ].join(":")
          end
          plan.roles_created.include?(role_id) || api.role(role_id).exists?
        end

        def error message
          # For now raise it, we can think about trying to recover down the road
          raise message
        end

        def log &block
          logger.debug('conjur/dsl2/planner') {
            yield
          }
        end

        def update_record
          update = Conjur::DSL2::Types::Update.new
          update.record = record

          changed = false
          record.custom_attribute_names.each do |attr|
            existing_value = if object.respond_to?(attr) 
              object.send(attr)
            else
              object.attributes[attr.to_s]
            end
            new_value = record.send(attr)
            if new_value
              if new_value == existing_value
                record.send "#{attr}=", nil
              else
                raise "Cannot modify immutable attribute '#{record.resource_kind}.#{attr}'" if record.immutable_attribute_names.member?(attr)
                changed = true
              end
            end
          end
          
          if record.resource?
            existing = resource.exists? ? resource.annotations : {}
            current = record.annotations.kind_of?(::Array) ? record.annotations[0] : record.annotations
            (record.annotations||{}).keys.each do |attr|
              existing_value = existing[attr]
              new_value = record.annotations[attr]
              if new_value == existing_value
                record.annotations.delete attr
              else
                changed = true
              end
            end
            
            if record.owner && resource.owner != record.owner.roleid
              give = Conjur::DSL2::Types::Give.new
              give.resource = Conjur::DSL2::Types::Resource.new(record.resourceid)
              give.owner = Conjur::DSL2::Types::Role.new(record.owner.roleid)
              action give
              
              if record.role?
                grant = Conjur::DSL2::Types::Grant.new
                grant.role = Conjur::DSL2::Types::Role.new(record.roleid)
                grant.member = Conjur::DSL2::Types::Member.new
                grant.member.role = Conjur::DSL2::Types::Role.new(record.owner.roleid)
                grant.member.admin = true
                action grant
              end
            end
          end
          
          action update if changed
        end
        
        def create_record
          create = Conjur::DSL2::Types::Create.new
          create.record = record
          
          if record.resource?
            existing = resource.exists? ? resource.annotations : {}
            # And this is why we don't name a class Array.
            current  = record.annotations.kind_of?(::Array) ? record.annotations[0] : record.annotations
            (current||{}).keys.each do |attr|
              existing_value = existing[attr]
              new_value = current[attr]
              if new_value == existing_value
               current.delete attr
              end
            end
          end

          plan.roles_created.add(record.roleid) if record.role?
          plan.resources_created.add(record.resourceid) if record.resource?
          action create
        end
      end
    end
  end
end
