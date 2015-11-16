require 'spec_helper'
require 'conjur/dsl2/ruby/loader'

include Conjur::DSL2

describe Planner do
  include_context "planner"
    
  let(:filename) { "spec/lib/planner/record_fixture.rb" }
  let(:group) { double(:group, exists?: group_exists, attributes: { 'gidnumber' => 1101 }) }
  let(:variable) { double(:variable, exists?: variable_exists, attributes: { 'mime_type' => "text/plain", 'kind' => "secret" }) }
  let(:group_resource) { double(:resource, exists?: group_exists, owner: "the-account:group:developers", annotations: {}) }
  let(:variable_resource) { double(:resource, exists?: variable_exists, owner: "the-account:variable:db-password", annotations: {}) }
  let(:cook_role) { double(:role, exists?: role_exists) }
  let(:bacon_resource) { double(:resource, exists?: resource_exists) }
  let(:simple_group) { Planner.planner_for(records[0], api) }
  let(:group_with_attributes) { Planner.planner_for(records[1], api) }
  let(:simple_variable) { Planner.planner_for(records[2], api) }
  let(:simple_role) { Planner.planner_for(records[3], api) }
  let(:resource_with_attributes) { Planner.planner_for(records[4], api) }
  let(:subject) { simple_group }

  let(:group_exists) { false }
  let(:variable_exists) { false }
  let(:role_exists) { false }
  let(:resource_exists) { false }
    
  before do
    allow(api).to receive(:group).with("developers").and_return group
    allow(api).to receive(:variable).with("db-password").and_return variable
    allow(api).to receive(:resource).with("the-account:group:developers").and_return group_resource
    allow(api).to receive(:resource).with("the-account:variable:db-password").and_return variable_resource
    allow(api).to receive(:role).with("the-account:job:cook").and_return cook_role
    allow(api).to receive(:resource).with("the-account:food:bacon").and_return bacon_resource
  end
  
  let(:plan_yaml) do
    plan = Plan.new
    subject.plan = plan
    subject.do_plan
    plan.actions.to_yaml
  end
  
  context "when group doesn't exist" do
    it "creates a group" do
        expect(plan_yaml).to eq(<<-YAML)
---
- service: directory
  type: group
  action: create
  path: groups
  parameters:
    id: developers
  description: Create group developers
        YAML
      end
    end
    context "when resource doesn't exist" do
    let(:subject) { resource_with_attributes }
    it "creates the resource" do
        expect(plan_yaml).to eq(<<-YAML)
---
- service: authz
  type: resource
  action: create
  method: put
  id: the-account:food:bacon
  path: authz/the-account/resources/food/bacon
  parameters: {}
  description: Create resource the-account:food:bacon
- service: authz
  type: annotation
  action: update
  id: the-account:food:bacon
  path: authz/the-account/annotations/food/bacon
  parameters:
    name: tastes
    value: Yummy
  description: Update 'tastes' annotation on the-account:food:bacon
      YAML
    end
  end
  context "when role doesn't exist" do
    let(:subject) { simple_role }
    it "creates the role" do
        expect(plan_yaml).to eq(<<-YAML)
---
- service: authz
  type: role
  action: create
  method: put
  path: authz/the-account/roles/job/cook
  id: the-account:job:cook
  parameters: {}
  description: Create role the-account:job:cook
  YAML
    end
  end
  context "when variable doesn't exist" do
    let(:subject) { simple_variable }
    it "creates a variable" do
        expect(plan_yaml).to eq(<<-YAML)
---
- service: directory
  type: variable
  action: create
  path: variables
  parameters:
    id: db-password
    kind: database password
    mime_type: text/plain
  description: Create variable db-password
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
    let(:group_exists) { true }
    it "it can be a nop" do
        expect(plan_yaml).to eq(<<-YAML)
--- []
      YAML
      end
      context "and has attributes" do
      let(:subject) { group_with_attributes }
      it "it will update gidnumber and annotations" do
          expect(plan_yaml).to eq(<<-YAML)
---
- service: directory
  type: group
  action: update
  path: groups/developers
  id: developers
  parameters:
    gidnumber: 1102
  description: Update 'gidnumber' on group developers
- service: authz
  type: annotation
  action: update
  id: the-account:group:developers
  path: authz/the-account/annotations/group/developers
  parameters:
    name: name
    value: Developers
  description: Update 'name' annotation on the-account:group:developers
    YAML
      end
    end
  end
end
