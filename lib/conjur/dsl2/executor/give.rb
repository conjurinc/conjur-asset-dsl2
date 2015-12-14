module Conjur::DSL2::Executor
  class Give < Base
    def execute
      action({
        'method' => 'put',
        'path' => resource_path,
        'parameters' => { "owner" => record.owner }
      })
    end
  end
end
