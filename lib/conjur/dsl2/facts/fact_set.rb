require 'set' # almost always already required, but you know...

module Conjur::DSL2::Facts
  class FactSet < Set
    attr_reader :replace_role_grants
    attr_reader :replace_resource_permits

    def initialize *a
      super *a

      @replace_role_grants = []
      @replace_resource_permits = []
    end
  end
end
