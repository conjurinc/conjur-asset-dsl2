module Conjur::DSL2::Facts
  # Provides helper methods to create facts without qualifying stuff
  module Helper
    def create_record_exists kind, id,owner
      Conjur::DSL2::Facts::RecordExists.new kind, id, owner
    end

    def create_has_role

    end
  end
end