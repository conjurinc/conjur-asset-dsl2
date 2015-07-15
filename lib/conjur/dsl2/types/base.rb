module Conjur
  module DSL2
    module Types
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
      
      class Base
        extend InheritableAttribute
        
        attr_accessor :owner
        
        inheritable_attr :yaml_fields
        
        self.yaml_fields = {}

        def role?
          false
        end
        
        def test_role r
          r.respond_to?(:role?) && r.role?          
        end
        
        def test_resource r
          r.respond_to?(:resource?) && r.resource?
        end
        
        def expect_resource r
          if test_resource(r)
            r
          else
            raise "Expecting Resource, got #{r}"
          end
        end
        
        def expect_role r
          if test_role(r)
            r
          else
            raise "Expecting Role, got #{r}"
          end
        end
        
        def expect_member m
          if m.is_a?(Member)
            m
          elsif test_role(m)
            Member.new m
          else
            raise "Expecting Member, got #{m}"
          end
        end
        
        def expect_permission p
          if p.is_a?(Permission)
            if !p.resource && test_resource(self)
              p.resource = self
            end
            p
          else
            raise "Expecting Permission, got #{p}"
          end
        end
                  
        def expect_string v
          raise "Expecting string, got #{v}" unless v.is_a?(String)
          v
        end
        
        def expect_boolean v
          v = true if v == "true"
          v = false if v == "false"
          raise "Expecting boolean, got #{v}" unless [ true, false ].member?(v)
          v
        end
        
        def expect_members members
          result = Array(members).map do |m|
            expect_member m
          end
          members.is_a?(Array) ? result : result[0]
        end

        def expect_roles roles
          result = Array(roles).map do |m|
            expect_role m
          end
          roles.is_a?(Array) ? result : result[0]
        end

        def expect_resources resources
          result = Array(resources).map do |m|
            expect_resource m
          end
          resources.is_a?(Array) ? result : result[0]
        end
        
        def expect_permissions permissions
          result = Array(permissions).map do |m|
            expect_permission m
          end
          permissions.is_a?(Array) ? result : result[0]
        end
        
        def expect_strings values
          result = Array(values).map do |v|
            expect_string v
          end
          values.is_a?(Array) ? result : result[0]
        end
        
        class << self
          def short_name
            self.name.split(':')[-1]
          end
          
          def yaml_field_type name
            self.yaml_fields[name]
          end
          
          def yaml_field? name
            !!self.yaml_fields[name]
          end
          
          def resource attr
            define_method attr do
              self.instance_variable_get("@#{attr}")
            end
            define_method "#{attr}=" do |v|
              self.instance_variable_set("@#{attr}", expect_resource(v))
            end
          end

          def resources attr
            define_method attr do
              self.instance_variable_get("@#{attr}")
            end
            define_method "#{attr}=" do |v|
              self.instance_variable_set("@#{attr}", expect_resources(v))
            end
          end
          
          def role attr
            define_method attr do
              self.instance_variable_get("@#{attr}")
            end
            define_method "#{attr}=" do |v|
              self.instance_variable_set("@#{attr}", expect_role(v))
            end
          end

          def roles attr
            define_method attr do
              self.instance_variable_get("@#{attr}")
            end
            define_method "#{attr}=" do |v|
              self.instance_variable_set("@#{attr}", expect_roles(v))
            end
          end
          
          def boolean attr
            define_method attr do
              self.instance_variable_get("@#{attr}")
            end
            define_method "#{attr}=" do |v|
              self.instance_variable_set("@#{attr}", expect_boolean(v))
            end
          end

          def string attr
            define_method attr do
              self.instance_variable_get("@#{attr}")
            end
            define_method "#{attr}=" do |v|
              self.instance_variable_set("@#{attr}", expect_string(v))
            end
          end
          
          def strings attr
            define_method attr do
              self.instance_variable_get("@#{attr}")
            end
            define_method "#{attr}=" do |v|
              self.instance_variable_set("@#{attr}", expect_strings(v))
            end
          end

          def member attr
            register_yaml_field attr.to_s, Member
            define_method attr do
              self.instance_variable_get("@#{attr}")
            end
            define_method "#{attr}=" do |v|
              self.instance_variable_set("@#{attr}", expect_member(v))
            end
          end
          
          def members attr
            register_yaml_field attr.to_s, Member
            define_method attr do
              self.instance_variable_get("@#{attr}")
            end
            define_method "#{attr}=" do |v|
              self.instance_variable_set("@#{attr}", expect_members(v))
            end
          end
          
          def permissions attr
            define_method attr do
              self.instance_variable_get("@#{attr}")
            end
            define_method "#{attr}=" do |v|
              self.instance_variable_set("@#{attr}", expect_permissions(v))
            end
          end
          
          def register_yaml_field field_name, type
            raise "YAML field #{field_name} already defined on #{self.name} as #{self.yaml_fields[field_name]}" if self.yaml_field?(field_name)
            self.yaml_fields[field_name] = type
          end
          
          def register_yaml_type simple_name
            YAML.add_tag "!#{simple_name}", self
          end
        end
      end
    end
  end
end
