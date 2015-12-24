module Conjur::DSL2::Executor
  class Update < Base
    include Annotate
    
    def execute
      statement.record.custom_attribute_names.each do |attr|
        value = statement.record.send(attr)
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
      require 'cgi'
      [ kind_path, CGI.escape(statement.record.id) ].join('/')
    end
    
    def annotate_record
      statement.record
    end
  end
end
