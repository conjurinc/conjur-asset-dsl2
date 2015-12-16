require 'spec_helper'
require 'conjur/dsl2/ruby/loader'

include Conjur::DSL2

describe Planner, planning: true do
  let(:filename) { "spec/lib/planner/managed_role_fixture.rb" }
  let(:api) { MockAPI.new 'the-account', fixture }
  let(:grant_plan) { Planner.planner_for(grant_record, api) }
  subject { grant_plan }

  let(:fixture) {
    Conjur::DSL2::YAML::Loader.load <<-YAML
---
- !layer bastion
- !group developers
- !group users
    YAML
  }

  describe "granting the member role" do
    let(:grant_record) { records[0] }
    context "when preconditions are satisfied" do
      it "grants the managed role" do
        expect(plan_descriptions).to eq(["Grant 'users' on layer 'bastion' to group 'developers'"])
        expect(plan_yaml).to eq(<<-YAML)
---
- !grant
  member: !member
    role: !group
      id: developers
  role: !managed-role
    record: !layer
      id: bastion
    role_name: users
        YAML
      end
    end
  end
  describe "granting multiple roles" do
    let(:grant_record) { records[1] }
    context "when preconditions are satisfied" do
      it "grants the managed role" do
        expect(plan_descriptions).to eq(["Grant group 'users' to group 'developers'", 
          "Grant 'users' on layer 'bastion' to group 'developers'"])
        expect(plan_yaml).to eq(<<-YAML)
---
- !grant
  member: !member
    role: !group
      id: developers
  role: !group
    id: users
- !grant
  member: !member
    role: !group
      id: developers
  role: !managed-role
    record: !layer
      id: bastion
    role_name: users
        YAML
      end
    end
  end
end
