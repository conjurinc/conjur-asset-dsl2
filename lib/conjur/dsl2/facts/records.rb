module Conjur::DSL2::Facts

  # This fact indicates that a record (variable, user, etc.) exists
  class RecordExists < Base
    kind :exists
    attributes :kind, :id, :owner

    def initialize kind, id, owner
      @kind, @id, @owner = kind, id, owner
    end
  end
end
