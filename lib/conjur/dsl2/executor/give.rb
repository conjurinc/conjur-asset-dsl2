module Conjur::DSL2::Executor
  # Change the owner of a resource with a PUT request to the resource path, specifying the new owner.
  class Give < Base
    def execute
      action({
        'method' => 'put',
        'path' => resource_path(statement.resource),
        'parameters' => { "owner" => statement.owner.roleid(default_account) }
      })
    end
  end
end
