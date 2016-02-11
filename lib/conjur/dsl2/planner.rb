require 'conjur/dsl2/plan'
require 'conjur/dsl2/planner/record'
require 'conjur/dsl2/planner/permissions'
require 'conjur/dsl2/planner/grants'

module Conjur
  module DSL2
    module Planner
      class << self
        def plan records, api, options = {}
          namespace = options[:namespace]
          ownerid   = options[:ownerid]
          plan = options[:plan] || Plan.new
          plan.tap do |plan|
            plan.namespace = namespace if namespace
            plan.ownerid = ownerid if ownerid
            Array(records).map{ |record| planner_for(record, api) }.sort.each do |planner|
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
