module Conjur::DSL2::Executor
  class Permit < Base
    def execute
      parameters = { "privilege" => privilege, "role" => role }
      parameters['grant_option'] = admin unless admin.nil?
      action({
        'method' => 'post',
        'path' => "authz/#{account}/resources/#{kind}/#{id}?permit",
        'parameters' => parameters
      })
    end

  end

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
