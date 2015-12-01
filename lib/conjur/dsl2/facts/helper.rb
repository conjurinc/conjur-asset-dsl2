module Conjur::DSL2::Facts
  # Provides helper methods to create facts without qualifying stuff
  module Helper
    def create_generic_record_exists kind, id,owner
      Conjur::DSL2::Facts::GenericRecordExists.new kind, id, owner
    end

    def create_grant role, member, admin_option
      Conjur::DSL2::Facts::Grant.new role, member, admin_option
    end

    def create_revoke role, member
      Conjur::DSL2::Facts::Revoke.new role, member
    end

    def create_permit resource, role, privilege, grant_option
      Conjur::DSL2::Facts::Permit.new resource, role, privilege, grant_option
    end

  end
end