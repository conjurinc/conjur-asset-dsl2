require 'conjur/api'

class Conjur::Role
  def can_admin_role? role
    return true if self.roleid == role.roleid
    
    memberships = self.memberships.map(&:roleid)
    role.members.find{|m| memberships.include?(m.member.roleid) && m.admin_option}
  end
end