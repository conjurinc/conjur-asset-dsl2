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
      
      module TopLevel
        def records &block
          Records.new.tap do |records|
            push records
            do_scope records, &block
          end
        end
        
        def permissions &block
          Permissions.new.tap do |permissions|
            push permissions
            do_scope permissions, &block
          end
        end
        
        def grants &block
          Grants.new.tap do |grants|
            push grants
            do_scope grants, &block
          end
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
      
      # List of records to create. Each one is a Conjur::DSL2::Types type.
      class Records < YAMLList
        include RecordFactory
      end
      
      # List of permissions. Each one is a Conjur::DSL2::Types::Permit or Deny.
      class Permissions < YAMLList
        def permit privilege, &block
          permit = Conjur::DSL2::Types::Permit.new(privilege)
          class << permit
            include RecordReferenceFactory
          end
          push permit
          do_scope permit, &block
        end
      end
      
      # List of role grants. Each one is a Conjur::DSL2::Types::Grant or Revoke.
      class Grants < YAMLList
        def grant &block
          grant = Conjur::DSL2::Types::Grant.new
          class << grant
            include RecordReferenceFactory
          end
          push grant
          do_scope grant, &block
        end
      end
      
      class Entitlements < YAMLList
        include TopLevel
        include Tagless
      end      
      
      # List of permissions. Each one is a Conjur::DSL2::Types type.
      class Policy
        include TopLevel
        
        def id val = nil
          if val
            @id = val
          else
            @id
          end
        end
        
        def records &block
          singleton :records, lambda { Records.new }, &block
        end
        
        def permissions &block
          singleton :permissions, lambda { Permissions.new }, &block
        end
        
        def grants &block
          singleton :grants, lambda { Grants.new }, &block
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
            super
          end
        end
      end
      
      class Loader
        include Delegation
        
        attr_reader :script, :filename
        
        class << self
          def create filename
            Loader.new(File.read(filename), filename)
          end
        end
        
        def initialize(script, filename = nil)
          @script = script
          @filename = filename
          @scope = []
        end

        def loader
          self
        end

        def load root
          args = [ script ]
          args << filename if filename
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
