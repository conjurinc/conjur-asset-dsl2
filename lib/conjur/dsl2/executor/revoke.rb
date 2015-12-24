module Conjur::DSL2::Executor
  class Revoke < Base
    def execute
      action({
        'method' => 'delete',
        'path' => "#{role_path(statement.role)}?members",
        'parameters' => { "member" => statement.member.roleid(default_account)}
      })
    end
  end
end
