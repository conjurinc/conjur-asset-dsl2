require 'spec_helper'
require 'conjur/dsl2/ruby/loader'

include Conjur::DSL2

describe Planner, planning: true do
  let(:filename) { "spec/lib/planner/record_fixture.rb" }
  let(:simple_group) { Planner.planner_for(records[0], api) }
  let(:group_with_attributes) { Planner.planner_for(records[1], api) }
  let(:api) { MockAPI.new 'the-account', fixture }

  context "when group doesn't exist" do
    let(:fixture) {
      Conjur::DSL2::YAML::Loader.load <<-YAML
[]
      YAML
    }
    let(:subject) { simple_group }
    it "creates a group" do
      expect(plan_descriptions).to eq([
        "Create group 'developers' in account 'the-account'"
      ])
      expect(plan_yaml).to eq(<<-YAML)
---
- !create
  record: !group
    account: the-account
    id: developers
        YAML
    end
  end
  
  context "when group exists with matching fields" do
    let(:fixture) {
      Conjur::DSL2::YAML::Loader.load <<-YAML
---
- !group
  id: developers
      YAML
    }
    context "with matching fields" do
      let(:subject) { simple_group }
      it "is nop" do
        expect(plan_descriptions).to eq([])
      end
    end
    context "with field changes" do
      let(:subject) { group_with_attributes }
      it "performs the updates" do
        expect(plan_descriptions).to eq(["Update group 'developers'\n\tSet field 'gidnumber'\n\tSet annotation 'name'"])
        expect(plan_yaml).to eq(<<-YAML)
---
- !update
  record: !group
    annotations:
      name: Developers
    gidnumber: 1102
    id: developers
        YAML
      end
    end
  end
end
