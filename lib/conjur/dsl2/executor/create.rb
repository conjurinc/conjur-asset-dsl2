module Conjur::DSL2::Executor
  class Create < Base
    def record
      statement.record
    end
  end

  class CreateRecord < Create
    def execute
      action({
        'method' => 'post',
        'path' => create_path,
        'parameters' => create_parameters
      })
    end
    
    def create_path
      [ kind_path ].join('/')
    end

    def update_path
      require 'cgi'
      [ kind_path, CGI.escape(record) ].join('/')
    end

    def kind_path
      record.resource_kind.pluralize
    end

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
  
  class CreateVariable < CreateRecord
    def create_parameters
      super.tap do |params|
        params['mime_type'] ||= 'text/plain'
        params['kind'] ||= 'secret'
      end
    end
  end
  
  module ActingAs
    def acting_as_parameters
      {}.tap do |params|
        params["acting_as"] = record.owner if record.owner
      end
    end
  end

  class CreateResource < Create
    include ActingAs
    
    def execute
      action({
        'method' => 'put',
        'path' => resource_path,
        'parameters' => acting_as_parameters
      })
    end
    
    def resource_path
      [ "authz", record.account, "resources", record.resource_kind, record.id ].join('/')
    end
  end

  class CreateRole < Create
    include ActingAs

    def execute
      action({
        'method' => 'put',
        'path' => role_path,
        'parameters' => acting_as_parameters
      })
    end

    def role_path
      [ "authz", record.account, "roles", record.role_kind, record.id ].join('/')
    end
  end
end