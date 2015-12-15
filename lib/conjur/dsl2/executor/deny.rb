module Conjur::DSL2::Executor
  class Deny < Base
    def execute
      action({
        'method' => 'post',
        'path' => "authz/#{account}/resources/#{kind}/#{id}?deny",
        'parameters' => { "privilege" => privilege, "role" => role }
      })
    end
  end
end
