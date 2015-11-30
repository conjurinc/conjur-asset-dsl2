module Conjur::DSL2
  module Facts
    class Base
      class << self
        def kind name=nil
          if name
            @kind = name
          end
          @kind
        end

        def attributes *args
          define_method(:equal_by){ args }
          protected(:equal_by)
          args.each{|s| attr_reader(s)}
        end
      end

      def to_s
        "<#{self.class.kind} " + equal_by.inject([]) do |s, attr|
          s << "#{attr}=#{send attr}"
        end.join(' ') + '>'
      end

      def == other
        return false unless self.class == other.class &&
          hash == other.hash
        equal_by.all?{|prop| send(prop) == other.send(prop) }
      end

      def hash
        @hash ||= (equal_by + [self.class.kind]).map{|prop| send(prop)}.hash
      end

    end
  end
end

require 'conjur/dsl2/facts/fact_set'
require 'conjur/dsl2/facts/grants'
require 'conjur/dsl2/facts/helper'
require 'conjur/dsl2/facts/permissions'
require 'conjur/dsl2/facts/records'

