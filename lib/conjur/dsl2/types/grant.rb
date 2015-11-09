module Conjur
  module DSL2
    module Types
      class Grant < Base
        attribute :role
        attribute :member
        attribute :exclusive, kind: :boolean, singular: true

        alias role_accessor role
        alias member_accessor member
        alias exclusive_accessor exclusive

        def exclusive v = nil
          if v
            self.exclusive = v
          else
            exclusive_accessor
          end
        end

        def role r = nil
          if r
            self.role = r
          else
            role_accessor
          end
        end
        
        def member r = nil, admin_option = false
          if r
            member = Member.new(r)
            member.admin = true if admin_option == true
            if self.member
              self.member = Array(self.member).push(member)
            else
              self.member = member
            end
          else
            member_accessor
          end
        end
      end
    end
  end
end
