module Conjur
  module DSL2
    module Planner
      class Base
        # Define a canonical order for Record types
        RECORD_ORDER = [
            Conjur::DSL2::Types::Create,
            Conjur::DSL2::Types::Permit,
            Conjur::DSL2::Types::Grant,
            Conjur::DSL2::Types::Deny,
            Conjur::DSL2::Types::Give,
            Conjur::DSL2::Types::Revoke
        ]

        RECORD_ORDER_KEYS = RECORD_ORDER.each_with_index.inject({}) do |hash, type_and_index|
          hash.merge type_and_index[0] => type_and_index[1]
        end

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
          account, kind, id = record.roleid(default_account).split(':', 3)
          [ account, kind, scoped_id(id) ].join(":")
        end

        def scoped_resourceid record
          account, kind, id = record.resourceid(default_account).split(':', 3)
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

        # Sort in canonical order
        def <=> other
          self_index  = RECORD_ORDER_KEYS[self.record.class]
          other_index = RECORD_ORDER_KEYS[other.record.class]
          if self_index.nil? or other_index.nil?
            puts "unknown types in #{self.class}, #{other.class}"
            0
          else
            self_index <=> other_index
          end
        end

        def resource_exists? resource_id
          plan.resources_created.include?(resource_id) ||  api.resource(resource_id).exists?
        end

        def role_exists? role_id
          plan.roles_created.include?(role_id) || api.role(role_id).exists?
        end

        def error message
          # For now raise it, we can think about trying to recover down the road
          raise message
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
            (record.annotations||{}).keys.each do |attr|
              existing_value = existing[attr]
              new_value = record.annotations[attr]
              if new_value == existing_value
                record.annotations.delete attr
              end
            end
          end

          plan.roles_created.add(record.roleid(account)) if record.role?
          plan.resources_created.add(record.resourceid(account)) if record.resource?
          action create
        end
      end
      
      class Array < Base
        def <=> other
          -1 # Array should always happen first, right?
        end

        def do_plan
          planners = record.map do |item|
            Planner.planner_for(item, api)
          end.sort!

          planners.each do |planner|
            planner.plan = self.plan
            planner.do_plan
          end
        end
      end
    end
  end
end
