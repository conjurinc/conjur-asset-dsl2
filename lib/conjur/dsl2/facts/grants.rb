module Conjur::DSL2
  module Facts
    class Granted < Base
      kind 'granted'
      attributes :role, :member, :grant_option

      def initialize role, member, grant_option
        @role, @member, @grant_option = role, member, grant_option
      end
    end

    class Revoked
      kind 'revoked'
      attributes :role, :member

      def initialize role, member
        @role, @member = role, member
      end
    end
  end
end