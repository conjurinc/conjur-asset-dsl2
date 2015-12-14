module Conjur
  module DSL2
    module Types
      class Retire < Base
        attribute :record, kind: :resource
        
        def to_s
          "Retire #{record}"
        end
      end
    end
  end
end

