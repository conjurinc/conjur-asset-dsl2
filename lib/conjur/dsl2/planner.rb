require 'conjur/dsl2/plan'
require 'conjur/dsl2/planner/record'
require 'conjur/dsl2/planner/permissions'
require 'conjur/dsl2/planner/grants'

module Conjur
  module DSL2
    module Planner
      class << self
        def plan records, api, plan = nil
          plan ||= Plan.new
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
