module Conjur::Policy
  module Executor
    require 'conjur/escape'
    
    # Builds a list of execution actions for a statement. The statement
    # is an object from Conjur::Policy::Types. Each execution action is
    # an HTTP method, a request path, and request parameters.
    class Base
      include Conjur::Policy::Logger
      include Conjur::Escape
      
      attr_reader :statement, :actions
      
      def initialize statement, actions
        @statement = statement
        @actions = actions
      end
      
      def action obj
        @actions.push obj
      end
      
      def execute
        raise "execute not implemented in #{self.class.name}"
      end
      
      def resource_path record = nil
        record ||= self.statement
        [ "authz", record.account, "resources", record.resource_kind, record.id ].join('/')
      end

      def role_path record = nil
        record ||= self.statement
        [ "authz", record.account, "roles", record.role_kind, record.id ].join('/')
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
        [ "authz", annotate_record.account,
            "annotations",
            annotate_record.resource_kind,
            CGI.escape(annotate_record.id) ].join('/')
      end
    end
  end
end
