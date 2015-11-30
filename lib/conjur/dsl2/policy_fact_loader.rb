module Conjur::DSL2
  class PolicyFactLoader
    attr_reader :root

    # @param root [Entitlements, Policy]
    def initialize root
      @root = root
    end

    def facts
      build_facts unless @facts
      @facts
    end

    def build_facts
      @facts = Conjur::DSL2::FactSet.new
    end


  end
end