require 'conjur/dsl2/plan'
require 'conjur/dsl2/planner/record'
require 'conjur/dsl2/planner/permissions'
require 'conjur/dsl2/planner/grants'

module Conjur
  module DSL2
    module Planner
      class << self
        def plan records, api, namespace = nil
          Plan.new.tap do |p|
            p.namespace = namespace
            records.map do |record|
              planner = planner_for(record, api)
              planner.plan = p
              begin
                planner.do_plan
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
