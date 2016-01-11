module Conjur
  module DSL2
    module Types
      class Grant < Base
        attribute :role, dsl_accessor: true
        attribute :member
        attribute :replace, kind: :boolean, singular: true, dsl_accessor: true
        
        include RoleMemberDSL
        include ManagedRoleDSL
        
        def to_s
          role_str = role.kind_of?(Array) ?
            role.join(', ') : role
          member_str = member.kind_of?(Array) ?
            member.map(&:role).join(', ') : member.role
          admin = member.kind_of?(Array) ?
            member.map(&:admin).all? : member.admin
          "Grant #{role_str} to #{member_str}#{replace ? ' exclusively ' : ''}#{admin ? ' with admin option' : ''}"
        end
      end
    end
  end
end
