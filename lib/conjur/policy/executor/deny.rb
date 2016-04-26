module Conjur::Policy::Executor
  # Deny a privilege with a POST request to the +deny+ url of the resource, with the privilege
  # and role as parameters.
  class Deny < Base
    def execute
      action({
        'method' => 'post',
        'path' => "#{resource_path(statement.resource)}?deny",
        'parameters' => { "privilege" => statement.privilege, "role" => statement.role.roleid }
      })
    end
  end
end
