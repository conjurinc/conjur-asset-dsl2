require 'conjur/dsl2/planner/base'

module Conjur
  module DSL2
    module Planner      
      class Role < Base
        def do_plan
          if role.exists?
            change_owner
          else
            create_record
          end
        end
      end
      
      class Resource < Base
        def do_plan
          if resource.exists?
            change_owner
            update_record
          else
            create_record
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
          record.owner = Conjur::DSL2::Types::Role.new "policy", plan.scoped_id(record)
          record.owner.account = record.account
          Resource.new(record, api).tap do |resource|
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
      
      class Record < Base
        def do_plan
          if object.exists?
            change_owner
            update_record
          else
            create_record
          end
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
