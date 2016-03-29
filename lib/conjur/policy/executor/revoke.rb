module Conjur::Policy::Executor
  class Revoke < Base
    def execute
      action({
        'method' => 'delete',
        'path' => "#{role_path(statement.role)}?members",
        'parameters' => { "member" => statement.member.roleid }
      })
    end
  end
end
