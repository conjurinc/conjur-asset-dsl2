module Conjur::DSL2
  module Facts
    class Base
      class << self
        def kind name
          define_method(:verb){ name }
        end

        def attributes *args
          attrs = args.push :verb
          define_method(:equal_by){ attrs }
          protected(:equal_by)
          attrs.each{|s| attr_reader(s)}
        end
      end

      def == other
        return false unless self.class == other.class &&
          hash == other.hash
        equal_by.all?{|prop| send(prop) == other.send(prop) }
      end

      def hash
        @hash ||= equal_by.map{|prop| send(prop)}.hash
      end

    end
  end
end

require 'conjur/dsl2/facts/fact_set'
require 'conjur/dsl2/facts/grants'
require 'conjur/dsl2/facts/helper'
require 'conjur/dsl2/facts/permissions'
require 'conjur/dsl2/facts/records'

