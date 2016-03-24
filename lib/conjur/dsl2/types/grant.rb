module Conjur::DSL2::Types
  class Grant < Base
    attribute :role, dsl_accessor: true
    attribute :member
    attribute :replace, kind: :boolean, singular: true, dsl_accessor: true

    include RoleMemberDSL
    include ManagedRoleDSL

    self.description = %(
Grant one role to another. (compare: Revoke)

[More](/key_concepts/rbac.html) on role-based access control in Conjur.
)

    self.example = %(
!user Link
!user Navi

!grant
  role: !user Navi
  member: !user Link
)

    def to_s
      role_str   = if role.kind_of?(Array)
                   then role.join(', ')
                   else role
                   end
      member_str = if member.kind_of?(Array)
                   then member.map(&:role).join(', ')
                   else member.role
                   end
      admin      = if member.kind_of?(Array)
                   then member.map(&:admin).all?
                   else member.admin
                   end
      "Grant #{role_str} to #{member_str}#{replace ? ' exclusively ' : ''}#{admin ? ' with admin option' : ''}"
    end
  end
end
