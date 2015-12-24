module Conjur::DSL2::Executor
  # Permit a privilege with a POST request to the +permit+ url of the resource, with the privilege
  # and role as parameters. +grant_option+ is also provided if it is explicitly stated on the Permit
  # record.
  class Permit < Base
    def execute
      parameters = { "privilege" => statement.privilege, "role" => statement.role.role.roleid(default_account) }
      parameters['grant_option'] = admin unless statement.role.admin.nil?
      action({
        'method' => 'post',
        'path' => "#{resource_path(statement.resource)}?permit",
        'parameters' => parameters
      })
    end
  end
end
