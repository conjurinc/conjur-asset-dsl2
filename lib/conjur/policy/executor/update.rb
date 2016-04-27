module Conjur::Policy::Executor
  class Update < Base
    include Annotate
    
    def execute
      statement.record.custom_attribute_names.each do |attr|
        value = statement.record.send(attr)
        next if value.nil?
        action({
          'method' => 'put',
          'path' => update_path,
          'parameters' => { attr.to_s => value }
        })
      end
      
      annotate
    end

    def kind_path
      statement.record.resource_kind.pluralize
    end
    
    def update_path
      [ kind_path, fully_escape(statement.record.id) ].join('/')
    end
    
    def annotate_record
      statement.record
    end
  end
end
