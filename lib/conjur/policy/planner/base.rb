module Conjur
  module Policy
    module Planner
      class Base
        include Conjur::Policy::Logger

        attr_reader :record, :api
        attr_accessor :plan

        def initialize record, api
          raise "Expecting Conjur::Policy::Types::Base, got #{record.class}" unless record.is_a?(Conjur::Policy::Types::Base)
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
            Conjur::Policy::Types::AutomaticRole.build fullid
          else
            if record_class = record_type(kind)
              record_class.new.tap do |record|
                record.account = account
                unless record.is_a?(Conjur::Policy::Types::Variable)
                  record.kind = kind if record.respond_to?(:kind=)
                end
                record.id = id
              end
            else
              Conjur::Policy::Types::Role.new(fullid)
            end
          end
        end
        
        def record_type kind
          begin
            Conjur::Policy::Types.const_get(kind.classify)
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
          logger.debug('conjur/policy/planner') {
            yield
          }
        end

        def update_record
          log { "Updating #{record}" }
          
          update = Conjur::Policy::Types::Update.new
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
                log { "Attribute #{attr} will be updated" }
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
                log { "Annotation #{attr} will be updated" }
                changed = true
              end
            end
            
            log { "Record owner is #{record.owner.roleid}" }
            log { "Resource owner is #{resource.owner}" }
            if record.owner && resource.owner != record.owner.roleid
              log { "Resource owner will be changed to #{record.owner.roleid}" }

              give = Conjur::Policy::Types::Give.new
              give.resource = Conjur::Policy::Types::Resource.new(record.resourceid)
              give.owner = Conjur::Policy::Types::Role.new(record.owner.roleid)
              action give
            end
          end

          if record.role?
            unless api.role(record.owner.roleid).can_admin_role?(role)
              log { "Role will be granted to #{record.owner.roleid} with admin option" }
  
              grant = Conjur::Policy::Types::Grant.new
              grant.role = Conjur::Policy::Types::Role.new(record.roleid)
              grant.member = Conjur::Policy::Types::Member.new
              grant.member.role = Conjur::Policy::Types::Role.new(record.owner.roleid)
              grant.member.admin = true
              action grant
            end
          end
          
          action update if changed
        end
        
        def create_record
          log { "Creating #{record}" }

          create = Conjur::Policy::Types::Create.new
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
