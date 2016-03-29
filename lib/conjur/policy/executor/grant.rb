module Conjur::Policy::Executor
  class Grant < Base
    def execute
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