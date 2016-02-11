module Conjur
  module DSL2
    module Planner
      class Base
        include Conjur::DSL2::Logger

        attr_reader :record, :api
        attr_accessor :plan

        def initialize record, api
          @record = record
          @api = api
        end
        
        def action a
          @plan.action a
        end
        
        def scoped_id id
          @plan.scoped_id id
        end
        
        def scoped_roleid record
          record = record.roleid(default_account) unless record.kind_of?(String)
          account, kind, id = record.split(':', 3)
          [ account, kind, scoped_id(id) ].join(":")
        end

        def scoped_resourceid record
          record = record.resourceid(default_account) unless record.kind_of?(String)
          account, kind, id = record.split(':', 3)
          [ account, kind, scoped_id(id) ].join(":")
        end
          
        def account
          (record.account rescue nil) || default_account
        end

        def default_account
          Conjur.configuration.account
        end
        
        def role_record fullid
          account, kind, id = fullid.split(':', 3)
          if kind == '@'
            Conjur::DSL2::Types::ManagedRole.build fullid, default_account
          else
            if record_class = record_type(kind)
              record_class.new.tap do |record|
                record.account = account unless account == default_account
                unless record.is_a?(Conjur::DSL2::Types::Variable)
                  record.kind = kind if record.respond_to?(:kind=)
                end
                record.id = id
              end
            else
              Conjur::DSL2::Types::Role.new(fullid, default_account: default_account)
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
          api.resource(scoped_resourceid record)
        end
        
        def role
          api.role(scoped_roleid record)
        end

        # Sort in canonical order -- basically, a `Record` or `Create` comes before everything
        # else.  So the base class's sort just places those before us, and anything else gets 0.
        def <=> other
          (other.kind_of?(Conjur::DSL2::Planner::ActsAsRecord) or other.kind_of?(Conjur::DSL2::Planner::Array)) ? 1 : 0
        end

        def resource_exists? resource
          resource_id = resource.kind_of?(String) ? resource : scoped_resourceid(resource)
          (plan.resources_created.include?(resource_id) ||  api.resource(resource_id).exists?)
        end

        def role_exists? role
          role_id = role.kind_of?(String) ? role : scoped_roleid(role)
          # I believe it's correct to assume manged roles exist?
          return true if role_id.split(':',2).last.start_with?('@')

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
          record.id = scoped_id(record)

          changed = false
          record.custom_attribute_names.each do |attr|
            existing_value = object.attributes[attr]
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
            
            if record.owner && resource.owner != scoped_roleid(record.owner)
              give = Conjur::DSL2::Types::Give.new
              give.resource = Conjur::DSL2::Types::Resource.new(record.resourceid(default_account), default_account: default_account)
              give.owner = Conjur::DSL2::Types::Role.new(scoped_roleid(record.owner), default_account: default_account)
              action give
              
              if record.role?
                grant = Conjur::DSL2::Types::Grant.new
                grant.role = Conjur::DSL2::Types::Role.new(record.roleid(default_account), default_account: default_account)
                grant.member = Conjur::DSL2::Types::Member.new
                grant.member.role = Conjur::DSL2::Types::Role.new(scoped_roleid(record.owner), default_account: default_account)
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
          record.id = scoped_id(record)
          if record.owner
            record.owner = Conjur::DSL2::Types::Role.new(scoped_roleid(record.owner), default_account: default_account)
          elsif plan.ownerid
            record.owner = Conjur::DSL2::Types::Role.new(plan.ownerid, default_account: default_account)
          end
          
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

          plan.roles_created.add(record.roleid(account)) if record.role?
          plan.resources_created.add(record.resourceid(account)) if record.resource?
          action create
        end
      end
      
      class Array < Base
        # Array sorts before everything because sanity.
        def <=> other
          -1
        end

        def do_plan

          planners = record.map do |item|
            Planner.planner_for(item, api)
          end.sort

          planners.each do |planner|
            planner.plan = self.plan
            planner.do_plan
          end
        end
      end
    end
  end
end
