module Conjur::DSL2::Types
  class Update < Base
    attribute :record

    self.description = %(
Make changes to an existing record's attributes.

For example, you can change annotations on a [Resource](#reference/resource), the `uidnumber` of a [User](#reference/user), etc.
)

    self.example = %(
- !user wizard
    annotations:
      color: gray

- !update
    record: !user wizard
      annotations:
        color: white
)
    
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
