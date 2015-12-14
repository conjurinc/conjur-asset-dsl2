module Conjur
  module DSL2
    module Types
      class Give < Base
        attribute :resource
        attribute :owner
        
        def to_s
          "Give #{resource} to #{owner}"
        end
      end
    end
  end
end
