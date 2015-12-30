module Conjur::DSL2::Executor
  class Grant < Base
    def execute
      parameters = { "member" => statement.member.role.roleid(default_account) }
      parameters['admin_option'] = statement.member.admin unless statement.member.admin.nil?
      action({
        'method' => 'put',
        'path' => "authz/#{statement.role.account || default_account}/roles/#{statement.role.role_kind}/#{statement.role.id}?members",
        'parameters' => parameters
      })
    end
  end
end