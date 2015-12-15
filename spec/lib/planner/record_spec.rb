require 'spec_helper'
require 'conjur/dsl2/ruby/loader'

include Conjur::DSL2

describe Planner, planning: true do
    
  let(:filename) { "spec/lib/planner/record_fixture.rb" }
  let(:group) { double(:group, exists?: group_exists, attributes: { 'gidnumber' => 1101 }) }
  let(:alice) { double(:user, exists?: user_exists, attributes: { 'uidnumber' => 1101 }) }
  let(:variable) { double(:variable, exists?: variable_exists, attributes: { 'mime_type' => "text/plain", 'kind' => "secret" }) }
  let(:user_resource) { double(:resource, exists?: user_exists, owner: "the-account:group:developers", annotations: {}) }
  let(:group_resource) { double(:resource, exists?: group_exists, owner: "the-account:group:developers", annotations: {}) }
  let(:variable_resource) { double(:resource, exists?: variable_exists, owner: "the-account:variable:db-password", annotations: {}) }
  let(:cook_role) { double(:role, exists?: role_exists) }
  let(:bacon_resource) { double(:resource, exists?: resource_exists) }
  let(:simple_group) { Planner.planner_for(records[0], api) }
  let(:group_with_attributes) { Planner.planner_for(records[1], api) }
  let(:simple_variable) { Planner.planner_for(records[2], api) }
  let(:simple_role) { Planner.planner_for(records[3], api) }
  let(:resource_with_attributes) { Planner.planner_for(records[4], api) }
  let(:simple_user) { Planner.planner_for(records[5], api) }

  let(:group_exists) { false }
  let(:user_exists) { false }
  let(:variable_exists) { false }
  let(:role_exists) { false }
  let(:resource_exists) { false }
    
  before do
    allow(api).to receive(:group).with("developers").and_return group
    allow(api).to receive(:user).with("alice").and_return alice
    allow(api).to receive(:variable).with("db-password").and_return variable
    allow(api).to receive(:resource).with("the-account:user:alice").and_return user_resource
    allow(api).to receive(:resource).with("the-account:group:developers").and_return group_resource
    allow(api).to receive(:resource).with("the-account:variable:db-password").and_return variable_resource
    allow(api).to receive(:role).with("the-account:job:cook").and_return cook_role
    allow(api).to receive(:resource).with("the-account:food:bacon").and_return bacon_resource
  end
  
  context "when group doesn't exist" do
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
  context "when user doesn't exist" do
    let(:subject) { simple_user }
    it "creates a user" do
      expect(plan_descriptions).to eq([
        "Create user 'alice' in account 'the-account'"
      ])
      expect(plan_yaml).to eq(<<-YAML)
---
- !create
  record: !user
    account: the-account
    id: alice
        YAML
    end
  end
  context "when resource doesn't exist" do
    let(:subject) { resource_with_attributes }
    it "creates the resource" do
      expect(plan_descriptions).to eq([
        "Create food 'bacon' in account 'the-account'\n\tSet annotation 'tastes'",
        ])
        expect(plan_yaml).to eq(<<-YAML)
---
- !create
  record: !resource
    account: the-account
    annotations:
      tastes: Yummy
    id: bacon
    kind: food
      YAML
    end
  end
  context "when role doesn't exist" do
    let(:subject) { simple_role }
    it "creates the role" do
      expect(plan_descriptions).to eq(["Create job 'cook' in account 'the-account'"])
        expect(plan_yaml).to eq(<<-YAML)
---
- !create
  record: !role
    account: the-account
    id: cook
    kind: job
  YAML
    end
  end
  context "when variable doesn't exist" do
    let(:subject) { simple_variable }
    it "creates a variable" do
      expect(plan_descriptions).to eq([
        "Create variable 'db-password' in account 'the-account'"
        ])
        expect(plan_yaml).to eq(<<-YAML)
---
- !create
  record: !variable
    account: the-account
    id: db-password
    kind: database password
      YAML
      end
    end
    context "when variable exists" do
    let(:subject) { simple_variable }
    let(:variable_exists) { true }
    it "mime_type is immutable" do
      expect { plan_yaml }.to raise_error("Cannot modify immutable attribute 'variable.kind'")
    end
  end
  context "when group exists" do
    let(:subject) { simple_group }
    let(:group_exists) { true }
    it "it can be a nop" do
      expect(plan_yaml).to eq(<<-YAML)
--- []
      YAML
      end
      context "and has attributes" do
      let(:subject) { group_with_attributes }
      it "it will update gidnumber and annotations" do
        expect(plan_descriptions).to eq([
          "Update group 'developers'\n\tSet field 'gidnumber'\n\tSet annotation 'name'",
        ])
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
