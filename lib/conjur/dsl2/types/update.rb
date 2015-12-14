module Conjur::DSL2::Types
  class Update < Base
    attribute :record
    
    def to_s
      messages = [ "Update #{record}" ]
      (record.annotations||{}).each do |k,v|
        messages.push "Set #{record} annotation '#{k}'"
      end
      messages.join("\n")
    end
  end
end
