module Conjur
  module DSL2
    module Types
      class Give < Base
        attribute :resource, kind: :resource
        attribute :owner, kind: :role
        
        def to_s
          "Give #{resource} to #{owner}"
        end
      end
    end
  end
end
