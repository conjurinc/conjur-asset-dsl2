class Object
  # Dear Ruby, I wish instance variables order was stable, because if it was
  # then YAML would always come out the same.
  def to_yaml_properties
    instance_variables.sort
  end
end

module Conjur
  module DSL2
    module Ruby
      module RecordLoader
        def respond_to_missing? sym, include_all = false
          super or Conjur::DSL2::Types.const_get sym.to_s.classify rescue nil
        end
      end
      
      # Implement +method_missing+ to reference basic types like Group, User, Layer, etc.
      # Anything from Conjur::DSL2::Types is fair game.
      module RecordReferenceFactory
        include RecordLoader
        
        # The record can have a constructor with 0 or 1 arguments. If it takes 1 argument,
        # it will be populated with the first +args+, if any. It's assumed to be the id.
        def method_missing sym, *args, &block
          kind = Conjur::DSL2::Types.const_get sym.to_s.classify rescue nil
          if kind
            object = kind.new(*args)
            raise "#{kind.short_name} is not createable here" unless object.role? || object.resource?
            handle_object object, &block
            object
          else
            super
          end
        end
        
        def handle_object object, &block
          # pass
        end
      end
      
      # Contsruct record properties in a block and yield the record to the loader.
      module RecordFactory
        include RecordReferenceFactory
        
        def handle_object object, &block
          push object
          do_scope object, &block
        end
      end
      
      class YAMLList < Array
        def tag
          [ "!", self.class.name.split("::")[-1].underscore ].join
        end
        
        def encode_with coder
          coder.represent_seq tag, self
        end
      end
      
      module Tagless
        def tag; nil; end
      end
      
      module Grants
        def grant &block
          grant = Conjur::DSL2::Types::Grant.new
          class << grant
            include RecordReferenceFactory
          end
          push grant
          do_scope grant, &block
        end
      end
      
      module Permissions
        def permit privilege, &block
          permit = Conjur::DSL2::Types::Permit.new(privilege)
          class << permit
            include RecordReferenceFactory
          end
          push permit
          do_scope permit, &block
        end
      end
      
      # Entitlements will allow creation of any record, as well as declaration
      # of permit, deny, grant and revoke.
      class Entitlements < YAMLList
        include Tagless
        include RecordFactory
        include Grants
        include Permissions
        
        def policy id=nil, &block
          policy = Policy.new
          policy.id(id) unless id.nil?
          push policy

          do_scope policy, &block
        end
      end
      
      class Body < YAMLList
        include RecordFactory
        include Grants
        include Permissions
      end
      
      # Policy includes the functionality of Entitlements, wrapped in a 
      # policy role, policy resource, policy id and policy version.
      class Policy < Conjur::DSL2::Types::Base
        include Conjur::DSL2::Types::ActsAsResource
        include Conjur::DSL2::Types::ActsAsRole
        
        def body &block
          singleton :body, lambda { Body.new }, &block
          @body
        end
        
        def body= body
          @body = body
        end
        
        protected
        
        def singleton id, factory, &block
          object = instance_variable_get("@#{id}")
          unless object
            object = factory.call
            class << object
              include Tagless
            end
            instance_variable_set("@#{id}", object)
          end
          do_scope object, &block
        end
      end
      
      module Delegation
        def respond_to? sym, include_all = false
          super or scope.respond_to?(sym, include_all)
        end
        
        def method_missing(sym, *args, &block)
          if scope.respond_to?(sym)
            scope.send sym, *args, &block
          else
            raise NoMethodError, "undefined method `#{sym}` for #{scope}:#{scope.class}"
          end
        end
      end
      
      class Loader
        include Delegation
        
        attr_reader :script, :filename
        
        class << self
          def load_file filename
            load File.read(filename), filename
          end

          def load yaml, filename = nil
            create(yaml, filename).load
          end

          def create(yaml, filename=nil)
            new(yaml, filename)
          end

        end
        
        def initialize script, filename = nil
          @script = script
          @filename = filename
          @scope = []
        end

        def loader
          self
        end

        def load root = nil
          args = [ script ]
          args << filename if filename
          root ||= Entitlements.new
          do_scope root do
            instance_eval(*args)
          end
          root
        end
        
        def push_scope obj
          @scope.push obj
        end
        
        def scope
          @scope.last
        end
        
        def pop_scope
          @scope.pop
        end
        
        def do_scope obj, &block
          push_scope obj
          class << obj
            attr_accessor :loader
            
            def do_scope obj, &block
              loader.do_scope obj, &block
            end
            
            def scope
              loader.scope
            end
            
            def to_yaml_properties
              super - [ :"@loader" ]
            end
          end
          obj.loader = self
          begin
            yield if block_given?
          ensure
            pop_scope
          end
        end
      end
      
      Psych.add_tag "!policy", Policy
    end
  end
end
