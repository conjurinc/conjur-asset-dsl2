module Conjur::DSL2::Types
  class Update < Base
    attribute :record
    
    def will_modify_fields?
      !annotations.empty? || !attributes.empty?
    end
    
    def annotations
      record.annotations || {}
    end
    
    def attributes
      (record.custom_attribute_names||[]).select{|a| record.send a}
    end
    
    def to_s
      messages = [ "Update #{record}" ]
      (record.custom_attribute_names||[]).each do |k|
        if record.send(k)
          raise "Cannot set immutable field '#{k}'" if record.immutable_attribute_names.member?(k)
          messages.push "\tSet field '#{k}'" 
        end
      end
      annotations.each do |k,v|
        messages.push "\tSet annotation '#{k}'"
      end
      messages.join("\n")
    end
  end
end
