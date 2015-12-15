module Conjur::DSL2::Executor
  class Update < Base
    def execute
      statement.record.custom_attribute_names.each do |attr|
        value = record.send(attr)
        action({ 
          'action' => 'put',
          'path' => update_path,
          'parameters' => { attr.to_s => value }
        })
      end
      
      statement.record.annotations.each do |k,v|
        action({
          'method' => 'put',
          'path' => update_annotation_path,
          'parameters' => { "name" => k, "value" => v }
        })
      end
    end
    
    def update_annotation_path
      [ "authz", account, "annotations", statement.record.resource_kind, statement.record.id ].join('/')
    end
  end
end
