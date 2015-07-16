module Conjur
  module DSL2
    module Types
      class Member < Base
        def initialize role = nil
          self.role = role if role
        end
        
        attribute :role
        attribute :admin, kind: :boolean, singular: true
      end
    end
  end
end
