module Conjur
  module DSL2
    module YAML
      class Handler < Psych::Handler
        attr_accessor :parser, :filename, :result
        
        # Override the logger with this method.
        cattr_accessor :logger
        
        require 'logger'
        
        self.logger = Logger.new(STDERR)
        self.logger.level = Logger::INFO
        
        # An abstract Base handler. The handler will receive each document message within
        # its particular context (sequence, mapping, etc).
        #
        # The handler can decide that the message is not allowed by not implementing the message.
        #
        class Base
          attr_reader :parent
          
          def initialize parent
            @parent = parent
          end
          
          # Each handler should implement this method to return the result object (which may only be
          # partially constructed). This method is used by the root handler to associate the handler
          # result with an anchor (if applicable).
          def result; raise "Not implemented"; end
          
          # Handlers are organized in a stack. Each handler can find the root Handler by traversing up the stack.
          def handler
            parent.handler
          end
          
          # Push this handler onto the stack.
          def push_handler
            handler.push_handler self
          end
          
          # Pop this handler off the stack, indicating that it's complete.
          def pop_handler
            handler.pop_handler
          end
          
          # An alias is encountered in the document. The value may be looked up in the root Handler +anchor+ hash.
          def alias anchor
            raise "Unexpected alias #{anchor}"
          end
          
          # Start a new mapping with the specified tag. 
          # If the handler wants to accept the message, it should return a new handler.
          def start_mapping tag
            raise "Unexpected mapping"
          end
          
          # Start a new sequence.
          # If the handler wants to accept the message, it should return a new handler.
          def start_sequence
            raise "Unexpected sequence"
          end
          
          # End the current sequence. The handler should populate the sequence into the parent handler.
          def end_sequence
            raise "Unexpected end of sequence"
          end
          
          # End the current mapping. The handler should populate the mapping into the parent handler.
          def end_mapping
            raise "Unexpected end of mapping"
          end
          
          # Process a scalar value. It may be a map key, a map value, or a sequence value.
          # The handler should return a result from this method, so that the root Handler can
          # associate it with an anchor, if any.
          def scalar value, tag, quoted
            raise "Unexpected scalar"
          end
          
          protected
          
          def scalar_value value, tag, quoted, record_type
            if type = type_of(tag, record_type)
              type.new.tap do |record|
                record.id = value
              end
            else
              SafeYAML::Transform.to_guessed_type(value, quoted, SafeYAML::OPTIONS)
            end
          end
          
          def type_of tag, record_type
            if tag && tag.match(/!(.*)/)
              type_name = $1.underscore.camelize
              begin
                Conjur::DSL2::Types.const_get(type_name)
              rescue NameError
                raise "Unrecognized data type '#{tag}'"
              end
            else
              record_type
            end
          end
        end
        
        # Handles the root document, which should be a sequence.
        class Root < Base
          attr_reader :result, :handler
          
          def initialize handler
            super nil
            
            @handler = handler
            @result = nil
          end
          
          def handler; @handler; end
          
          def sequence seq
            raise "Already got sequence result" if @result
            @result = seq
          end
          
          # The document root is expected to start with a sequence. 
          # A Sequence handler is constructed with no implicit type. This
          # sub-handler handles the message.
          def start_sequence
            Sequence.new(self, nil).tap do |h|
              h.push_handler
            end.result
          end
          
          # Finish the sequence, and the document.
          def end_sequence
            pop_handler
          end
        end
        
        # Handles a sequence. The sequence has:
        # +record_type+ default record type, inferred from the field name on the parent record.
        # +args+ the start_sequence arguments.
        class Sequence < Base
          attr_reader :record_type
          
          def initialize parent, record_type
            super parent
            
            @record_type = record_type
            @list = []
          end
          
          def result; @list; end
          
          # Adds a mapping to the sequence.
          def mapping value
            @list.push value
          end
  
          # Adds a sequence to the sequence.
          def sequence value
            @list.push value
          end
          
          # When the sequence receives an alias, the alias should be mapped to the previously stored 
          # value and added to the result list.
          def alias anchor
            @list.push handler.anchor(anchor)
          end
          
          # When the sequence contains a mapping, a new record should be created corresponding to either:
          #
          # * The explicit stated type (tag) of the mapping
          # * The implicit field type of the sequence
          #
          # If neither of these is available, it's an error.
          def start_mapping tag
            if type = type_of(tag, record_type)
              Mapping.new(self, type).tap do |h|
                h.push_handler
              end.result
            else
              raise "No type given or inferred for sequence entry"
            end
          end
          
          # Process a sequence within a sequence.
          def start_sequence
            Sequence.new(self, record_type).tap do |h|
              h.push_handler
            end.result
          end
          
          # When the sequence contains a scalar, the value should be appended to the result.
          def scalar value, tag, quoted
            scalar_value(value, tag, quoted, record_type).tap do |value|
              @list.push value
            end
          end
          
          def end_sequence
            parent.sequence @list
            pop_handler
          end
        end
        
        # Handles a mapping, each of which will be parsed into a structured record.
        class Mapping < Base
          attr_reader :type
          
          def initialize parent, type
            super parent
            
            @record = type.new
          end
  
          def result; @record; end
          
          def map_entry key, value
            if @record.respond_to?(:[]=)
              @record.send(:[]=, key, value)
            else
              begin
                @record.send("#{key}=", value)
              rescue NoMethodError
                raise "No such attribute '#{key}' on type #{@record.class.short_name}"
              end
            end
          end
          
          # Begins a mapping with the anchor value as the key.
          def alias anchor
            key = handler.anchor(anchor)
            MapEntry.new(self, @record, key).tap do |h|
              h.push_handler
            end.result
          end
  
          # Begins a new map entry.
          def scalar value, tag, quoted
            value = scalar_value(value, tag, quoted, type)
            MapEntry.new(self, @record, value).tap do |h|
              h.push_handler
            end.result
          end
          
          def end_mapping
            parent.mapping @record
            pop_handler
          end
        end
        
        # Processes a map entry. At this point, the parent record and the map key are known.
        class MapEntry < Base
          attr_reader :record, :key
  
          def initialize parent, record, key
            super parent
            
            @record = record
            @key = key
          end
          
          def result; nil; end
          
          def sequence value
            value value
          end
          
          def mapping value
            value value
          end
          
          def value value
            parent.map_entry @key, value
            pop_handler
          end
          
          # Interpret the alias as the map value and populate in the parent.
          def alias anchor
            value handler.anchor(anchor)
          end
          
          # Start a mapping as a map value.
          def start_mapping tag
            if type = type_of(tag, yaml_field_type(key))
              Mapping.new(self, type).tap do |h|
                h.push_handler
              end.result
            else
              # We got a mapping on a simple type
              raise "Attribute '#{key}' can't be a mapping"
            end
          end
          
          # Start a sequence as a map value.
          def start_sequence
            Sequence.new(self, yaml_field_type(key)).tap do |h|
              h.push_handler
            end.result
          end
          
          def scalar value, tag, quoted
            value scalar_value(value, tag, quoted, yaml_field_type(key))
          end
          
          protected
          
          def yaml_field_type key
            record.class.respond_to?(:yaml_field_type) ? record.class.yaml_field_type(key) : nil
          end
        end
        
        def initialize
          @root = Root.new self
          @handlers = [ @root ]
          @anchors = {}
          @filename = "<no-filename>"
        end
        
        def push_handler handler
          log {"#{indent}pushing handler #{handler.class}"}
          @handlers.push handler
        end
          
        def pop_handler
          @handlers.pop
          log {"#{indent}popped to handler #{handler.class}"}
        end
        
        # Get or set an anchor. Invoke with just the anchor name to get the value.
        # Invoke with the anchor name and value to set the value.
        def anchor *args
          key, value, _ = args
          if _
            raise ArgumentError, "Expecting 1 or 2 arguments, got #{args.length}"
          elsif key && value
            raise "Duplicate anchor #{key}" if @anchors[key]
            @anchors[key] = value
          elsif key
            @anchors[key]
          else
            nil
          end
        end
        
        def result; @root.result; end
        
        def handler; @handlers.last; end
        
        def alias key
          log {"#{indent}anchor '#{key}'=#{anchor(key)}"}
          handler.alias key
        end
        
        def start_mapping *args
          log {"#{indent}start mapping #{args}"}
          anchor, tag, _ = args
          value = handler.start_mapping tag
          anchor anchor, value
        end
        
        def start_sequence *args
          log {"#{indent}start sequence : #{args}"}
          anchor, _ = args
          value = handler.start_sequence
          anchor anchor, value
        end
        
        def end_sequence
          log {"#{indent}end sequence"}
          handler.end_sequence
        end
        
        def end_mapping
          log {"#{indent}end mapping"}
          handler.end_mapping
        end
        
        def scalar *args
          # value, anchor, tag, plain, quoted, style
          value, anchor, tag, _, quoted = args
          log {"#{indent}got scalar #{tag ? tag + '=' : ''}#{value}#{anchor ? '#' + anchor : ''}"}
          value = handler.scalar value, tag, quoted
          anchor anchor, value
        end
        
        def log &block
          logger.debug('conjur/dsl2/handler') {
            yield
          }
        end
        
        def indent
          "  " * [ @handlers.length - 1, 0 ].max
        end
      end
    end
  end
end