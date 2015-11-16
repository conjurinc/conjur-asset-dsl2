module Conjur
  module DSL2
    module Planner
      class Base
        attr_reader :record, :api
        attr_accessor :plan
        
        def initialize record, api
          @record = record
          @api = api
        end
        
        def action a
          @plan.action a
        end
        
        def scoped_id id
          @plan.scoped_id id
        end
        
        def scoped_roleid record
          account, kind, id = record.roleid(default_account).split(':', 3)
          [ account, kind, scoped_id(id) ].join(":")
        end

        def scoped_resourceid record
          account, kind, id = record.resourceid(default_account).split(':', 3)
          [ account, kind, scoped_id(id) ].join(":")
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