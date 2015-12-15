module Conjur::DSL2::Executor
  class Revoke < Base
    def execute
      action({
        'method' => 'delete',
        'path' => "authz/#{account}/roles/#{kind}/#{id}?members",
        'parameters' => { "member" => member }
      })
    end
  end
end