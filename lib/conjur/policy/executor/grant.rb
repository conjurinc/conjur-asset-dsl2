module Conjur::Policy::Executor
  class Grant < Base
    def execute
      if statement.role.is_a?(Conjur::Policy::Types::Layer) && statement.member.role.is_a?(Conjur::Policy::Types::Host)
        add_host_to_layer
      else
        grant_role_to_member
      end
    end
    
    def add_host_to_layer
      parameters = { "hostid" => statement.member.role.roleid }
      action({
        'method' => 'post',
        'path' => "layers/#{fully_escape statement.role.id}/hosts",
        'parameters' => parameters
      })
    end
    
    def grant_role_to_member
      parameters = { "member" => statement.member.role.roleid }
      parameters['admin_option'] = statement.member.admin unless statement.member.admin.nil?
      action({
        'method' => 'put',
        'path' => "authz/#{statement.role.account}/roles/#{statement.role.role_kind}/#{statement.role.id}?members",
        'parameters' => parameters
      })
    end
  end
end
