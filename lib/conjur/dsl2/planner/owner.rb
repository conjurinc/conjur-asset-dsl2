require 'conjur/dsl2/planner/base'

module Conjur
  module DSL2
    module Planner
      # This action is required if the resource owner doesn't match the record.owner, or 
      # if the record.owner doesn't have the record role with grant option.
      class Owner < Base
        def do_plan
          if resource && record.owner && resource.owner != scoped_roleid(record.owner)
            give = Conjur::DSL2::Types::Give.new
            give.resource = resource
            give.owner = record.owner
            action give
          end
        end
      end
    end
  end
end
