module Conjur::Policy::Executor
  class Revoke < Base
    def execute
      if statement.role.is_a?(Types::Layer) && statement.member.is_a?(Types::Host)
        remove_host_from_layer
      else
        revoke_role_from_member
      end
    end
    
    def remove_host_from_layer
      action({
        'method' => 'delete',
        'path' => "layers/#{fully_escape statement.role.id}/hosts/#{fully_escape statement.member.roleid}",
        'parameters' => {}
      })
    end
    
    def revoke_role_from_member
      action({
        'method' => 'delete',
        'path' => "#{role_path(statement.role)}?members",
        'parameters' => { "member" => statement.member.roleid }
      })
    end
  end
end
