module Conjur
  module DSL2
    module Planner
      class Base
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
          record.account || default_account
        end

        def default_account
          Conjur.configuration.account
        end
        
        def role_record fullid
          account, kind, id = fullid.split(':', 3)
          Conjur::DSL2::Types.const_get(kind.classify).new.tap do |record|
            record.account = account unless account == default_account
            record.kind = kind if record.respond_to?(kind)
            record.id = id
          end
        end
        
        alias resource_record role_record
        
        def resource
          api.resource(scoped_resourceid record)
        end
        
        def role
          api.role(scoped_roleid record)
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
                record.send "@#{attr}=", nil
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
              give.resource = Conjur::DSL2::Types::Resource.new(record.resourceid(default_account))
              give.owner = Conjur::DSL2::Types::Role.new scoped_roleid(record.owner)
              action give
              
              if record.role?
                grant = Conjur::DSL2::Types::Grant.new
                grant.role = Conjur::DSL2::Types::Role.new(record.roleid(default_account))
                grant.member = Conjur::DSL2::Types::Member.new
                grant.member.role = Conjur::DSL2::Types::Role.new scoped_roleid(record.owner)
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
          record.account ||= default_account
          record.id = scoped_id(record)
          if record.owner
            record.owner = scoped_roleid(record.owner.roleid) 
          elsif plan.ownerid
            record.owner = plan.ownerid
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
          
          action create
        end
      end
    end
  end
end