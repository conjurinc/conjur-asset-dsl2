module Conjur::DSL2::Types
  class Create < Base
    attribute :record
        
    def to_s
      messages = [ "Create #{record}" ]
      if record.resource?
        (record.annotations||{}).each do |k,v|
          messages.push "  Set annotation '#{k}'"
        end
      end
      messages.join("\n")
    end
  end
end
