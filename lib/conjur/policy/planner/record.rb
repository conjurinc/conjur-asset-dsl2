require 'conjur/policy/planner/base'

module Conjur
  module Policy
    module Planner      
      module ActsAsRecord
        def do_plan
          if exists?
            update_record
          else
            create_record
          end
        end

        def to_s
          "<#{self.class.name} #{record.to_s}>"
        end
      end
      
      class Role < Base
        include ActsAsRecord
        
        alias object role

        def exists?
          plan.role_exists?(role.roleid)
        end

      end
      
      class Resource < Base
        include ActsAsRecord
        
        alias object resource

        def exists?
          plan.resource_exists?(resource.resourceid)
        end

      end
      
      class Record < Base
        include ActsAsRecord
        
        def object
          raise "Cannot create a record in non-default account #{record.account}" unless record.account == Conjur.configuration.account
          @object ||= api.send(record.resource_kind, record.id)
        end

        def exists?
          plan.resource_exists?(object.resourceid)
        end

      end
      
      class Webservice < Resource
      end

      class Policy < Base
        def do_plan
          unless record.body.nil?
            error('Not expecting a body element in policy')
          end
          
          # Create the role
          Role.new(record.role, api).tap do |role|
            role.plan = plan
            role.do_plan
          end

          # Copy the annotations
          Hash(record.annotations).each do |k,v|
            record.resource.annotations ||= {}
            record.resource.annotations[k] = v
          end

          # Create the resource
          Resource.new(record.resource, api).tap do |resource|
            resource.plan = plan
            resource.do_plan
          end
        end
      end
    end
  end
end
