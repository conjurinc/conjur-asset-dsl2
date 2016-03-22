module Conjur::DSL2::Types
  class Create < Base
    attribute :record

    self.description = %(
Create a record.
)

    self.example = %(
!create
  !group experiment
!create
  !group control
)
        
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
