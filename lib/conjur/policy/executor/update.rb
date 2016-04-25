module Conjur::Policy::Executor
  class Update < Base
    include Annotate
    
    def execute
      attribute_names.each do |attr|
        value = record.send(attr)
        if value
          action({ 
            'method' => 'put',
            'path' => update_path,
            'parameters' => { attr.to_s => value }
          })
        end
      end
      
      annotate
    end

    def kind_path
      record.resource_kind.pluralize
    end
    
    def update_path
      require 'cgi'
      [ kind_path, CGI.escape(record.id) ].join('/')
    end
    
    def annotate_record
      record
    end
    
    def record
      statement.record
    end

    def attribute_names
      record.custom_attribute_names
    end
  end
  
  class UpdateUser < Update
    include PublicKeys
    
    def execute
      super

      p record
      
      if record.public_keys
        (Array(record.public_keys) - user.public_keys).each do |key|
          action({
            'method' => 'post',
            'path' => public_key_path,
            'parameters' => key
          })
        end
        (user.public_keys - Array(record.public_keys)).each do |key|
          action({
            'method' => 'delete',
            'path' => [ public_key_path, CGI.escape(key_name(key)) ].join('/')
          })
        end
      end
    end
    
    def user
      api.user record.id
    end

    def key_name key
      key.split(' ')[-1]
    end
  end
end
