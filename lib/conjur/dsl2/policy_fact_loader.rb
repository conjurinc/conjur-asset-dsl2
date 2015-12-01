module Conjur::DSL2
  class PolicyFactLoader
    include Conjur::DSL2::Facts::Helper
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
      @facts = Conjur::DSL2::Facts::FactSet.new
      @visitor = Conjur::DSL2::Visitor.new self
      @visitor.visit @root
    end

    def visit_policy policy
      puts "visit policy #{policy.id}" # TODO Create a resource I suppose?
      @visitor.visit_each(policy.body)
    end

    def visit_entitlements ents
      @visitor.visit_each(ents)
    end

    def visit_grant grant
      replace = grant.replace
      roles = Array(grant.role)
      roles.each{|r| @facts.replace_role_grants << r.roleid(account) }

      Array(grant.members).product(roles).each do |member, role|
        @facts << create_grant(role.roleid(account), member.role.roleid(account), !!m.admin)
      end
    end

    def visit_user rec
      
    end

    def visit_group rec

    end

    def visit_host rec

    end

    def visit_layer rec

    end

    def visit_variable rec

    end

    def visit_webservice rec

    end

    # Delete this!
    def default_visit obj
      puts "TODO implement visitor for #{obj.class}"
    end


  end
end