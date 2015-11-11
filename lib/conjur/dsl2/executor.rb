module Conjur
  module DSL2
    class Executor
      def initialize api, plan
        @api = api
        @plan = plan
      end
      
      def execute
        require 'net/http'
        uri = URI.parse(Conjur.configuration.appliance_url)
        Net::HTTP.start uri.host, uri.port do |http|
          @http = http
          @plan.each do |step|
            invoke step
          end
        end
      end
      
      protected
      
      def invoke step
        method, path, parameters = step
        send method, path, parameters
      end
      
      def post path, parameters
        uri = [ Conjur.configuration.appliance_url, path ].join('/')
        request = Net::HTTP::POST.new uri
        request.set_form_data parameters
        request['Authorization'] = "Authorization token=\"#{@api.token}\""
        response = @http.request request
        p response
      end
    end
  end
end