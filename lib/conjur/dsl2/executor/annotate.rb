module Conjur::DSL2::Executor
  class Annotate < Base
    def execute
      record.annotations.each do |k,v|
        action({
          'method' => 'put',
          'path' => update_annotation_path,
          'parameters' => { "name" => k, "value" => v }
        })
      end

      def update_annotation_path
        [ "authz", account, "annotations", record.resource_kind, record.id ].join('/')
      end
    end
  end
end
