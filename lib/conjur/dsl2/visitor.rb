require 'active_support/inflector'

module Conjur::DSL2
  # Visitor uses a `target` object (composition > inheritance) that is expected
  # to implement methods like `visit_some_class` to visit objects of class `SomeClass`.
  #
  # If the target does not implement a method for a particular class, it's bases and
  # included modules will be searched for a class/module that is handled.
  class Visitor
    attr_reader :target

    def initialize target
      @target = target
      @dispatch_cache = {}
    end

    def visit obj
      method = dispatch_method(obj.class)
      raise NoMethodError "target #{target.class.name} has no visit method for #{obj.class.name}" unless method
      target.send method, obj
    end

    private
    # Return a symbol for the method to invoke with an instance of this class
    def dispatch_method klass
      @dispatch_cache[klass] ||= find_dispatch_method(klass)
    end

    def find_dispatch_method klass
      each_superclass_and_module(klass) do |type|
        name = method_name_for_type(type)
        return name if target.respond_to?(name)
      end
    end

    def method_name_for_type class_or_module
      :"visit_#{class_or_module.name.split('::').last.underscore}"
    end

    def each_superclass_and_module klass, &blk
      yield klass
      modules = klass.included_modules # these after superclasses
      until klass.superclass.nil?
        yield klass = klass.superclass
      end
      modules.each(&blk)
    end
  end
end