module Conjur
  module DSL2
    module Types
      class Permit < Base
        attribute :role, kind: :member
        attribute :privilege, kind: :string
        attribute :resource
        attribute :exclusive, kind: :boolean, singular: true
        
        alias role_accessor role
        alias resource_accessor resource
        alias exclusive_accessor exclusive
        
        def initialize privilege = nil
          self.privilege = privilege
        end

        def exclusive v = nil
          if v
            self.exclusive = v
          else
            exclusive_accessor
          end
        end
        
        def role r = nil, grant_option = nil
          if r
            member = Member.new(r)
            member.admin = true if grant_option == true
            if self.role
              self.role = Array(self.role).push(member)
            else
              self.role = member
            end
          else
            role_accessor
          end
        end
        
        def resource r = nil
          if r
            self.resource = r
          else
            resource_accessor
          end
        end
      end
    end
  end
end
