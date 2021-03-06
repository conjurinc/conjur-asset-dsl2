require 'conjur/policy/plan'
require 'conjur/policy/planner/record'
require 'conjur/policy/planner/permissions'
require 'conjur/policy/planner/grants'

module Conjur
  module Policy
    module Planner
      class << self
        def plan records, api, plan = nil
          plan ||= Plan.new(api.resources, api.role_graph(api.current_role))
          plan.tap do |plan|
            Array(records).map{ |record| planner_for(record, api) }.each do |planner|
              planner.plan = plan
              planner.log { %Q(Planning "#{planner.record} using #{planner.class}") }
              begin
                planner.do_plan
                planner.log { "\tFinished \"#{planner.record}\"" }
              ensure
                planner.plan = nil
              end
            end
          end
        end
        
        def planner_for record, api
          cls = begin
            const_get record.class.name.split("::")[-1]
          rescue NameError
            Record
          end
          cls.new record, api
        end
          
      end
    end
  end
end
