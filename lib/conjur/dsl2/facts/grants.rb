module Conjur::DSL2
  module Facts
    class Grant < Base
      kind :grant
      attributes :role, :member, :admin_option

      def initialize role, member, admin_option
        @role, @member, @admin_option = role, member, admin_option
      end
    end

    class Revoke < Base
      kind :revoke
      attributes :role, :member

      def initialize role, member
        @role, @member = role, member
      end
    end
  end
end