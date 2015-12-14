module Conjur::DSL2::Executor
  class Grant < Base
    def execute
      parameters = { "member" => member }
      parameters['admin_option'] = admin unless admin.nil?
      action({
        'method' => 'put',
        'path' => "authz/#{account}/roles/#{kind}/#{id}?members",
        'parameters' => parameters
      })
    end
  end

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