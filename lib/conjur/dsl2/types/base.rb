module Conjur
  module DSL2
    module Types
      # An inheritable class attribute which is cloned by subclasses so the attribute
      # can be a mutable thing such as a Hash.
      #
      # https://raw.githubusercontent.com/apotonick/uber/master/lib/uber/inheritable_attr.rb
      module InheritableAttribute
        def inheritable_attr(name, options={})
          instance_eval %Q{
            def #{name}=(v)
              @#{name} = v
            end
    
            def #{name}
              return @#{name} if instance_variable_defined?(:@#{name})
              @#{name} = InheritableAttribute.inherit_for(self, :#{name}, #{options})
            end
          }
        end
    
        def self.inherit_for(klass, name, options={})
          return unless klass.superclass.respond_to?(name)
    
          value = klass.superclass.send(name) # could be nil
    
          return value if options[:clone] == false
          Clone.(value) # this could be dynamic, allowing other inheritance strategies.
        end
    
        class Clone
          # The second argument allows injecting more types.
          def self.call(value, uncloneable=uncloneable())
            uncloneable.each { |klass| return value if value.kind_of?(klass) }
            value.clone
          end
    
          def self.uncloneable
            [Symbol, TrueClass, FalseClass, NilClass]
          end
        end
      end
      
      # Methods which type-check and transform attributes. Type-checking can be done by 
      # duck-typing, with +is_a?+, or by a procedure.
      module TypeChecking
        # This is the primary function of the module.
        #
        # +value+ an input value
        # +type_name+ used only for error messages.
        # +test_function+ a class or function which will determine if the value is already the correct type.
        # +converter+ if the +test_function+ fails, the converter is called to coerce the type. 
        # It should return +nil+ if its unable to do so.
        def expect_type value, type_name, test_function, converter = nil
          if test_function.is_a?(Class)
            cls = test_function
            test_function = lambda{ value.is_a?(cls) } 
          end
          if test_function.call
            value
          elsif converter && ( v = converter.call )
            v
          else
            name = value.class.respond_to?(:short_name) ? value.class.short_name : value.class.name
            raise "Expecting #{type_name}, got #{name}"
          end
        end

        # Duck-type roles.
        def test_role r
          r.respond_to?(:role?) && r.role?          
        end
        
        # Duck-type resources.
        def test_resource r
          r.respond_to?(:resource?) && r.resource?
        end
        
        # If it looks like a resource.
        def expect_resource value
          expect_type value, "Resource", lambda{ test_resource value }
        end
        
        # If it looks like a role.
        def expect_role value
          expect_type value, "Role", lambda{ test_role value }
        end
        
        # +value+ may be a Member; Roles can also be converted to Members.
        def expect_member value
          expect_type value, 
            "Member", 
            Member,
            lambda{ Member.new(value) if test_role(value) }
        end
        
        # +value+ must be a Permission.
        def expect_permission value
          expect_type value, 
            "Permission", 
            Permission
        end
                  
        # +value+ must be a String.
        def expect_string value
          expect_type value, 
            "string",
            String
        end

        # +value+ must be a Integer.
        def expect_integer value
          expect_type value, 
            "integer",
            Integer
        end
                
        # +value+ can be a Hash, or an object which implements +to_h+.
        def expect_hash value
          expect_type value, 
            "hash",
            lambda{ value.is_a?(Hash)},
            lambda{ value.to_h.stringify_keys if value.respond_to?(:to_h) }
        end
        
        # +v+ must be +true+ or +false+.
        def expect_boolean v
          v = true if v == "true"
          v = false if v == "false"
          expect_type v, 
            "boolean",
            lambda{ [ true, false ].member?(v) }
        end
        
        # +values+ can be an instance of +type+ (as determined by the type-checking methods), or
        # it must be an array of them.
        def expect_array kind, values
          result = Array(values).map do |v|
            send "expect_#{kind}", v
          end
          values.is_a?(Array) ? result : result[0]
        end
      end
      
      # Define type-checked attributes, using the facilities defined in 
      # +TypeChecking+.
      module AttributeDefinition
        # Define a singular field.
        #
        # +attr+ the name of the field
        # +kind+ the type of the field, which corresponds to a +TypeChecking+ method.
        # +type+ a DSL object type which the parser should use to process the field.
        # This option is not used for simple kinds like :boolean and :string, because they are
        # not structured objects.
        def define_field attr, kind, type = nil, dsl_accessor = false
          register_yaml_field attr.to_s, type if type
          
          if dsl_accessor
            define_method attr do |*args|
              v = args.shift
              if v
                existing = self.instance_variable_get("@#{attr}")
                value = if existing
                  Array(existing) + [ v ]
                else
                  v
                end
                self.instance_variable_set("@#{attr}", self.class.expect_array(kind, value))
              else
                self.instance_variable_get("@#{attr}")
              end
            end
          else
            define_method attr do
              self.instance_variable_get("@#{attr}")
            end
          end
          define_method "#{attr}=" do |v|
            self.instance_variable_set("@#{attr}", self.class.expect_array(kind, v))
          end
        end
        
        # Define a plural field. A plural field is basically just an alias to the singular field.
        # For example, a plural field called +members+ is really just an alias to +member+. Both
        # +member+ and +members+ will accept single values or Arrays of values.
        def define_plural_field attr, kind, type = nil, dsl_accessor = false
          define_field attr, kind.to_s, type, dsl_accessor
          
          register_yaml_field attr.to_s.pluralize, type if type
          
          define_method attr.to_s.pluralize do |*args|
            send attr, *args
          end
          define_method "#{attr.to_s.pluralize}=" do |v|
            send "#{attr}=", v
          end
        end
        
        # This is the primary method used by concrete types to define their attributes. 
        #
        # +attr+ the singularized attribute name.
        # 
        # Options:
        # +type+ a structured type to be constructed by the parser. If not provided, the type
        # may be inferred from the attribute name (e.g. an attribute called :member is the type +Member+).
        # +kind+ the symbolic name of the type. Inferred from the type, if the type is provided. Otherwise
        # it's mandatory.
        # +singular+ by default, attributes accept multiple values. This flag restricts the attribute
        # to a single value only.
        def attribute attr, options = {}
          type = options[:type]
          begin
            type ||= Conjur::DSL2::Types.const_get(attr.to_s.capitalize) 
          rescue NameError
          end
          kind = options[:kind] 
          kind ||= type.short_name.downcase.to_sym if type
          
          raise "Attribute :kind must be defined, explicitly or inferred from :type" unless kind
          
          if options[:singular]
            define_field attr, kind, type, options[:dsl_accessor]
          else
            define_plural_field attr, kind, type, options[:dsl_accessor]
          end
        end
        
        # Ruby type for attribute name.
        def yaml_field_type name
          self.yaml_fields[name]
        end
        
        # Is there a Ruby type for a named field?
        def yaml_field? name
          !!self.yaml_fields[name]
        end
                  
        protected
        
        # +nodoc+
        def register_yaml_field field_name, type
          raise "YAML field #{field_name} already defined on #{self.name} as #{self.yaml_fields[field_name]}" if self.yaml_field?(field_name)
          self.yaml_fields[field_name] = type
        end
      end
      
      # Base class for implementing structured DSL object types such as Role, User, etc.
      #
      # To define a type:
      # 
      # * Inherit from this class
      # * Define attributes using +attribute+
      #
      # Your new type will automatically be registered with the YAML parser with a tag
      # corresponding to the lower-cased short name of the class. 
      class Base
        extend InheritableAttribute
        extend TypeChecking
        extend AttributeDefinition
        
        # On creation, an owner can always be specified.
        attr_accessor :owner
        
        # Stores the mapping from attribute names to Ruby class names that will be constructed
        # to populate the attribute.
        inheritable_attr :yaml_fields
        
        # +nodoc+
        self.yaml_fields = {}

        # Things aren't roles by default
        def role?
          false
        end
        
        def custom_attribute_names
          [ ]
        end
        
        class << self
          # Hook to register the YAML type.
          def inherited cls
            cls.register_yaml_type cls.short_name.underscore.gsub('_', '-')
          end
          
          # The last token in the ::-separated class name.
          def short_name
            self.name.demodulize
          end
          
          def register_yaml_type simple_name
            ::YAML.add_tag "!#{simple_name}", self
          end
        end
      end
      
      # Define DSL accessor for Role +member+ field.
      module RoleMemberDSL
        def self.included(base)
          base.module_eval do
            alias member_accessor member
            
            def member r = nil, admin_option = false
              if r
                member = Member.new(r)
                member.admin = true if admin_option == true
                if self.member
                  self.member = Array(self.member).push(member)
                else
                  self.member = member
                end
              else
                member_accessor
              end
            end
          end
        end
      end
      
      # Define DSL accessor for Resource +role+ field.
      module ResourceMemberDSL
        def self.included(base)
          base.module_eval do
            alias role_accessor role
            
            def role r = nil, grant_option = nil
              if r
                role = Member.new(r)
                role.admin = true if grant_option == true
                if self.role
                  self.role = Array(self.role) + [ role ]
                else
                  self.role = role
                end
              else
                role_accessor
              end
            end
          end
        end
      end
      
      module ManagedRoleDSL
        def managed_role record, role_name
          self.role = ManagedRole.new(record, role_name)
        end
      end
    end
  end
end
