module Conjur
  module DSL2
    module Executor
    end
  end
end

require 'conjur/dsl2/executor/base'
require 'conjur/dsl2/executor/create'
require 'conjur/dsl2/executor/give'
require 'conjur/dsl2/executor/grant'
require 'conjur/dsl2/executor/revoke'
require 'conjur/dsl2/executor/permit'
require 'conjur/dsl2/executor/deny'
require 'conjur/dsl2/executor/retire'
require 'conjur/dsl2/executor/update'

module Conjur
  module DSL2
    module Executor
      class << self
        def creator_class_for create
          class_name = create.record.class.name.split("::")[-1]
          begin
            Conjur::DSL2::Executor.const_get([ "Create", class_name ].join)
          rescue NameError
            Conjur::DSL2::Executor::CreateRecord
          end
        end
      end
    end
    
    class BasicExecutor
      class << self
        def collect plan
          result = []
          plan.actions.each do |record|
            class_name = action.class.name.split("::")[-1]
            executor = Conjur::DSL2::Executor.const_get(class_name).new(record, api, result)
            executor.execute
          end
          result
        end
        
        def execute plan
          actions = collect plan
          
          require 'net/https'
          uri = URI.parse(Conjur.configuration.appliance_url)
          @base_path = uri.path
          Net::HTTP.start uri.host, uri.port, use_ssl: true do |http|
            @http = http
            actions.each do |step|
              invoke step
            end
          end
        end
      end
    end
    
    class HTTPExecutor
      def initialize api
        @api = api
      end
      
      def execute actions
        require 'net/https'
        uri = URI.parse(Conjur.configuration.appliance_url)
        @base_path = uri.path
        Net::HTTP.start uri.host, uri.port, use_ssl: true do |http|
          @http = http
          actions.each do |step|
            invoke step
          end
        end
      end
      
      protected
      
      def invoke step
        send step['method'], step['path'], step['parameters']
      end
      
      def create path, parameters
        request = Net::HTTP::Post.new [ @base_path, path ].join('/')
        request.set_form_data parameters
        send_request request
      end

      alias post create
      
      def update path, parameters
        request = Net::HTTP::Put.new [ @base_path, path ].join('/')
        request.set_form_data parameters
        send_request request
      end
      
      alias put update
      
      def delete path, parameters
        uri = URI.parse([ @base_path, path ].join('/'))
        uri.query = [uri.query, parameters.map{|k,v| [ k, URI.escape(v) ].join('=')}.join("&")].compact.join('&') 
        request = Net::HTTP::Delete.new [ uri.path, '?', uri.query ].join
          
        send_request request
      end

      def send_request request
        # $stderr.puts "#{request.method.upcase} #{request.path} #{request.body}"
        require 'base64'
        request['Authorization'] = "Token token=\"#{Base64.strict_encode64 @api.token.to_json}\""
        response = @http.request request
        # $stderr.puts response.code
        if response.code.to_i >= 300
          $stderr.puts "#{request.method.upcase} #{request.path} #{request.body} failed with error #{response.code}:"
          # $stderr.puts "Request failed with error #{response.code}:"
          $stderr.puts response.body
        end
      end
    end
  end
end