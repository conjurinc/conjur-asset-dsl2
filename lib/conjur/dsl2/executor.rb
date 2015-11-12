module Conjur
  module DSL2
    class Executor
      def initialize api, actions
        @api = api
        @actions = actions
      end
      
      def execute
        require 'net/https'
        uri = URI.parse(Conjur.configuration.appliance_url)
        @base_path = uri.path
        Net::HTTP.start uri.host, uri.port, use_ssl: true do |http|
          @http = http
          @actions.each do |step|
            invoke step
          end
        end
      end
      
      protected
      
      def invoke step
        method, path, parameters = step

        def update_annotation_path
          [ "authz", account, "annotations", record.resource_kind, scoped_id(record) ].join('/')
        end

        send step['action'], step['path'], step['parameters']
      end
      
      def create path, parameters
        request = Net::HTTP::Post.new [ @base_path, path ].join('/')
        request.set_form_data parameters
        send_request request
      end
      
      def update path, parameters
        request = Net::HTTP::Put.new [ @base_path, path ].join('/')
        request.set_form_data parameters
        send_request request
      end

      def send_request request
        require 'base64'
        request['Authorization'] = "Token token=\"#{Base64.strict_encode64 @api.token.to_json}\""
        response = @http.request request
        if response.code.to_i >= 300
          $stderr.puts "#{request.method.upcase} #{request.path} #{request.body} failed with error #{response.code}:"
          $stderr.puts response.body
        end
      end
    end
  end
end