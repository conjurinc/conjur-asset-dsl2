module Conjur::DSL2::Executor
  # Abstract base class for creating a new record.
  class Create < Base
    def record
      statement.record
    end
    
    def account
      record.account || default_account
    end
  end

  # Generic 'create' implementation which POSTs to a resources URL.
  class CreateRecord < Create
    include Annotate
    
    def execute
      action({
        'method' => 'post',
        'path' => create_path,
        'parameters' => create_parameters
      })
      annotate
    end
    
    def annotate_record
      record
    end
    
    def create_path
      [ kind_path ].join('/')
    end

    def kind_path
      record.resource_kind.pluralize
    end

    # Each record is assumed to have an 'id' attribute required for creation.
    # In addition, other create parameters can be specified by the +custom_attribute_names+
    # method on the record.
    def create_parameters
      {
        record.id_attribute => record.id
      }.tap do |params|
        custom_attrs = record.custom_attribute_names.inject({}) do |memo, attr|
          value = record.send(attr)
          memo[attr.to_s] = value if value
          memo
        end
        params.merge! custom_attrs
        params["ownerid"] = record.owner.roleid if record.owner
      end
    end
  end

  # When creating a host factory, the +roleid+ and +layer+ are required.
  class CreateHostFactory < CreateRecord
    def create_parameters
      super.tap do |params|
        params['roleid'] = record.role.roleid(default_account)
        params['layers'] =  Array(record.layers).map(&:id)
      end
    end
  end

  # When creating a variable, set default values for the +mime_type+ and +kind+.  
  class CreateVariable < CreateRecord
    def create_parameters
      super.tap do |params|
        params['mime_type'] ||= 'text/plain'
        params['kind'] ||= 'secret'
      end
    end
  end
  
  # When creating a raw Role or Resource, the owner of the new record is specified by
  # the +acting_as+ parameter.
  module ActingAs
    def acting_as_parameters
      {}.tap do |params|
        params["acting_as"] = record.owner.roleid(default_account) if record.owner
      end
    end
  end

  # Create a new Resource with a PUT request to the resource path.
  class CreateResource < Create
    include ActingAs
    include Annotate
    
    def execute
      action({
        'method' => 'put',
        'path' => resource_path(statement.record),
        'parameters' => acting_as_parameters
      })
      annotate
    end
    
    def annotate_record
      statement.record
    end
  end

  # Create a new Role with a PUT request to the role path.
  class CreateRole < Create
    include ActingAs

    def execute
      action({
        'method' => 'put',
        'path' => role_path(statement.record),
        'parameters' => acting_as_parameters
      })
    end
  end
end
