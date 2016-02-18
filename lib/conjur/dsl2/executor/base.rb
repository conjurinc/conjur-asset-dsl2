module Conjur::DSL2
  module Executor
    # Builds a list of execution actions for a statement. The statement
    # is an object from Conjur::DSL2::Types. Each execution action is
    # an HTTP method, a request path, and request parameters.
    class Base
      include Conjur::DSL2::Logger
      
      attr_reader :statement, :actions, :default_account
      
      def initialize statement, actions, default_account
        @statement = statement
        @actions = actions
        @default_account = default_account
      end
      
      def action obj
        @actions.push obj
      end
      
      def execute
        raise "execute not implemented in #{self.class.name}"
      end
      
      def resource_path record = nil
        record ||= self.statement
        [ "authz", record.account || default_account, "resources", record.resource_kind, record.id ].join('/')
      end

      def role_path record = nil
        record ||= self.statement
        [ "authz", record.account || default_account, "roles", record.role_kind, record.id ].join('/')
      end
    end
    
    module Annotate
      def annotate
        Array(annotate_record.annotations).each do |k,v|
          action({
            'method' => 'put',
            'path' => update_annotation_path,
            'parameters' => { "name" => k, "value" => v }
          })
        end
      end
      
      def update_annotation_path
        [ "authz", annotate_record.account || default_account,
            "annotations",
            annotate_record.resource_kind,
            CGI.escape(annotate_record.id) ].join('/')
      end
    end
  end
end
