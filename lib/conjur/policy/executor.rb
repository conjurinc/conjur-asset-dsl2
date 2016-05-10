module Conjur
  module Policy
    module Executor
    end
  end
end

require 'conjur/policy/executor/base'
require 'conjur/policy/executor/create'
require 'conjur/policy/executor/give'
require 'conjur/policy/executor/grant'
require 'conjur/policy/executor/revoke'
require 'conjur/policy/executor/permit'
require 'conjur/policy/executor/deny'
require 'conjur/policy/executor/retire'
require 'conjur/policy/executor/update'

module Conjur
  module Policy
    module Executor
      class << self
        def class_for action
          if action.is_a?(Conjur::Policy::Types::Create)
            class_name = action.record.class.name.split("::")[-1]
            begin
              Conjur::Policy::Executor.const_get([ "Create", class_name ].join)
            rescue NameError
              Conjur::Policy::Executor::CreateRecord
            end
          else
            action_name = action.class.name.split("::")[-1]
            if action.respond_to?(:record)
              type_name = action.record.class.short_name
            end
            begin
              Conjur::Policy::Executor.const_get([ action_name, type_name ].compact.join)
            rescue NameError
              Conjur::Policy::Executor.const_get(action_name)
            end
          end
        end
      end
    end
        
    class HTTPExecutor
      attr_reader :api, :context
      
      # @param [Conjur::API] api
      def initialize api
        @api = api
        @context = {}
      end
      
      def execute actions
        require 'net/https'
        uri = URI.parse(Conjur.configuration.appliance_url)
        use_ssl = uri.scheme == 'https'
        @base_path = uri.path
        Net::HTTP.start uri.host, uri.port, use_ssl: use_ssl do |http|
          @http = http
          actions.each do |step|
            invoke step
          end
        end

        @context
      end
      
      protected
      
      def invoke step
        send step['method'], step['path'], step['parameters']
      end
      
      def create path, parameters
        request = Net::HTTP::Post.new [ @base_path, path ].join('/')
        set_request_body request, parameters
        send_request request
      end

      alias post create
      
      def update path, parameters
        request = Net::HTTP::Put.new [ @base_path, path ].join('/')
        set_request_body request, parameters
        send_request request
      end
      
      alias put update
      
      def delete path, parameters
        uri = URI.parse([ @base_path, path ].join('/'))
        unless parameters.blank?
          uri.query = [uri.query, parameters.to_query(nil)].compact.join('&') 
        end
        request = Net::HTTP::Delete.new [ uri.path, '?', uri.query ].join
          
        send_request request
      end

      def send_request request
        # $stderr.puts "#{request.method.upcase} #{request.path} #{request.body}"
        require 'base64'
        request['Authorization'] = "Token token=\"#{Base64.strict_encode64 @api.token.to_json}\""
        request['X-Conjur-Privilege'] = api.privilege if api.privilege
        response = @http.request request
        # $stderr.puts response.code
        if response.code.to_i >= 300
          $stderr.puts "#{request.method.upcase} #{request.path} #{request.body} failed with error #{response.code}:"
          # $stderr.puts "Request failed with error #{response.code}:"
          $stderr.puts response.body
        else
          update_context_from_response response
        end
      end

      def update_context_from_response response
        return if response.body.nil? or response.body.empty?
        response_json = JSON.parse response.body
        unless response_json['api_key'].nil?
          @context[response_json['roleid']] = response_json['api_key']
        end
      rescue JSON::ParserError
        # empty
      end
      
      def set_request_body request, params
        if params.is_a?(String)
          request.body = params
        else
          request.set_form_data to_params(params)
        end
      end
      
      # Convert parameter keys to rails []-style keys
      def to_params params
        Array(params).inject({}) do |memo,entry|
          key, value = entry
          if value.is_a?(Array)
            key = "#{key}[]"
          end
          memo[key] = value
          memo
        end
      end
    end
  end
end