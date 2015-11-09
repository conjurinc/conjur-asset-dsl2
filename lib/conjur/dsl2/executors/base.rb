module Conjur
  module DSL2
    module Executors
      class BaseExecutor
        attr_reader :record, :api
        
        def initialize record, api
          @record = record
          @api = api
        end
        
        def account
          record.account || default_account
        end

        def default_account
          Conjur.configuration.account
        end
      end
    end
  end
end