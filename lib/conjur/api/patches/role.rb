require 'conjur/api'

class Conjur::Role
  # This role can admin the target +role+ if this role has a role which is an admin member of
  # +role+. This determination is made by expanding all roles of +self+, then doing the set 
  # intersection with the direct members of +role+, and looking for an overlapping member that
  # has +admin_option+.
  def can_admin_role? role
    return true if self.roleid == role.roleid
    
    memberships = self.memberships.map(&:roleid)
    role.members.any?{|m| memberships.include?(m.member.roleid) && m.admin_option}
  end
end