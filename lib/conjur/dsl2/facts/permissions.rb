module Conjur::DSL2
  module Facts
    class Permit < Base
      kind :permit
      attributes :resource, :role, :privilege, :grant_option

      def initialize resource, role, privilege, grant_option
        @resource, @role, @privilege, @grant_option =
            resource, role, privilege, grant_option
      end
    end

  end
end
