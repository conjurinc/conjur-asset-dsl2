module Conjur::DSL2::Types
  class Create < Base
    attribute :record

    self.description = %(
Create any type of record.
)

    self.example = %(
- !create
    record: !user research
- !create
    record: !group experiment
- !create
    record: !role control
      kind: experimental_control
      owner: !user research
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
