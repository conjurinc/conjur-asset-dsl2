require 'conjur/dsl2/planner/base'

module Conjur
  module DSL2
    module Planner      
      module ActsAsRecord
        def do_plan
          if object.exists?
            update_record
          else
            create_record
          end
        end
      end
      
      class Role < Base
        include ActsAsRecord
        
        alias object role
      end
      
      class Resource < Base
        include ActsAsRecord
        
        alias object resource
      end
      
      class Record < Base
        include ActsAsRecord
        
        def object
          @object ||= api.send(record.resource_kind, scoped_id(record))
        end
      end
      
      class Webservice < Resource
      end

      class Policy < Base
        def do_plan
          role = record.role(default_account)
          Role.new(role, api).tap do |role|
            role.plan = plan
            role.do_plan
          end
          plan.ownerid = role.roleid(account)
          resource = record.resource(default_account)
          Resource.new(resource, api).tap do |resource|
            resource.plan = plan
            resource.do_plan
          end
          record.body.each do |record|
            ownerid = plan.ownerid
            begin
              plan.policy = self.record
              plan.ownerid = plan.policy.roleid(account)
              
              planner = Planner.planner_for(record, api)
              planner.plan = plan
              planner.do_plan
            ensure
              plan.policy = nil
              plan.ownerid = ownerid
            end
          end
        end
      end
    end
  end
end
