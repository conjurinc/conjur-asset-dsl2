require 'conjur-asset-dsl2'

module Conjur
  module DSL2
    module Executors
      class Create
        attr_reader :record, :api
        
        def initialize record, api
          @record = record
          @api = api
        end
        
        def execute
          creator = begin
            Conjur::DSL2::Executors.const_get [ record.class.short_name, "Create" ].join
          rescue NameError  
            CommonCreate
          end
          creator.new(record, api).create
        end
      end
      
      class GroupCreate
        attr_reader :record, :api
        
        def initialize record, api
          @record = record
          @api = api
        end
        
        def create
          options = {}
          options[:gidnumber] = record.gidnumber if record.gidnumber
          api.create_group(record.id, options).tap do |group|
            (record.annotations||{}).each do |k,v|
              group.annotations[k] = v
            end
          end
        end
      end
    end
  end
end
