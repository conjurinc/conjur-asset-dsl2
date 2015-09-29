require 'conjur-asset-dsl2'
require 'conjur/dsl2/executors/create'

module Conjur
  module DSL2
    class Executor
      attr_reader :records
      attr_accessor :owner
      
      def initialize records
        @records = records
      end
      
      def execute
        records.each do |record|
          executor = Conjur::DSL2::Executors.const_get record.action.to_s.classify
          executor.new(record, self).execute
        end
        nil
      end
      
      def merge_options options
        options.dup.tap do |opts|
          opts[:ownerid] = owner if owner
          opts[:acting_as] = owner if owner
        end
      end
    end
    
    class LiveExecutor < Executor
      attr_reader :api
      
      def initialize records, api
        super records
        
        @api = api
      end

      def create_group id, options = {}
        group = api.group(id)
        if group.exists?
          if Conjur.log
            Conjur.log << "Group '#{id}' exists\n"
          end
        else
          group = api.create_group(id, merge_options(options))
        end
        group
      end
    end
    
    class DryRunExecutor < Executor
      attr_reader :actions
        
      def initialize records
        super records
        
        @actions = []
      end
      
      def execute
        super
        
        actions
      end

      def create_group id, options = {}
        @actions.push [ kind: :group, id: id, options: merge_options(options), annotations: annotations = {}]
        OpenStruct.new(annotations: annotations)
      end
    end
  end
end
