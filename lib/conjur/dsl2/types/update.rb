module Conjur::DSL2::Types
  class Update < Base
    attribute :record
    
    def to_s
      messages = [ "Update #{record}" ]
      (record.custom_attribute_names||[]).each do |k|
        messages.push "  Set field '#{k}'" 
      end
      (record.annotations||{}).each do |k,v|
        messages.push "  Set annotation '#{k}'"
      end
      messages.join("\n")
    end
  end
end
