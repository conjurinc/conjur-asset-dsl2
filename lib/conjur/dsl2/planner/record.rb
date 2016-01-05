require 'conjur/dsl2/planner/base'

module Conjur
  module DSL2
    module Planner      
      module ActsAsRecord
        # Record objects sort before everything else
        def <=> other
          other.kind_of?(ActsAsRecord) ? 0 : -1
        end

        def do_plan
          if object.exists?
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

          if record.body.nil?
            error('missing body element in policy')
          end

          plan.ownerid = role.roleid(account)
          resource = record.resource(default_account)
          if record.annotations
            resource.annotations = record.annotations
          end

          Resource.new(resource, api).tap do |resource|
            resource.plan = plan
            resource.do_plan
          end

          planners = record.body.map do |record|
            Planner.planner_for(record, api)
          end.sort

          planners.each do |planner|
            ownerid = plan.ownerid
            begin
              plan.policy = self.record
              
              # Set the ownerid to the namespace-scoped roleid of the policy
              ownerid = plan.policy.roleid(account)
              if plan.namespace
                account, kind, id = ownerid.split(':', 3)
                ownerid = [ account, kind, [ plan.namespace, id ].join("/") ].join(":")
              end
              ownerid = ownerid
              plan.ownerid = ownerid

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
