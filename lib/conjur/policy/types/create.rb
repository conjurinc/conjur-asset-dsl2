module Conjur::Policy::Types
  class Create < Base
    attribute :record

    self.description = %(
Create a record of any type.

A record can be a [Role](#reference/role) or a [Resource](#reference/resource).

Creating records can be done explicitly using this node type, or
implicitly. Examples of both are given immeditely below.
)

    self.example = %(
- !user research # implicit record creation
- !create        # explicit record creation
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
