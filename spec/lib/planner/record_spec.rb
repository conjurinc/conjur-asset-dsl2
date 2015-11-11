require 'spec_helper'
require 'conjur/dsl2/ruby/loader'

include Conjur::DSL2

describe Planner do
  include_context "planner"
    
  let(:filename) { "spec/lib/planner/record_fixture.rb" }
  let(:group) { double(:group, exists?: group_exists, gidnumber: 1101) }
  let(:variable) { double(:variable, exists?: variable_exists, mime_type: "text/plain", kind: "secret") }
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
    subject.plan plan
    plan.actions.to_yaml
  end
  
  context "when group doesn't exist" do
    it "creates a group" do
        expect(plan_yaml).to eq(<<-YAML)
---
- - POST
  - groups
  - id: developers
        YAML
      end
    end
    context "when resource doesn't exist" do
    let(:subject) { resource_with_attributes }
    it "creates the resource" do
        expect(plan_yaml).to eq(<<-YAML)
---
- - PUT
  - authz/the-account/resources/food/bacon
  - {}
- - PUT
  - authz/the-account/annotations/food/bacon
  - name: tastes
    value: Yummy
      YAML
    end
  end
  context "when role doesn't exist" do
    let(:subject) { simple_role }
    it "creates the role" do
        expect(plan_yaml).to eq(<<-YAML)
---
- - PUT
  - authz/the-account/roles/job/cook
  - {}
  YAML
    end
  end
  context "when variable doesn't exist" do
    let(:subject) { simple_variable }
    it "creates a variable" do
        expect(plan_yaml).to eq(<<-YAML)
---
- - POST
  - variables
  - id: db-password
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
- - PUT
  - groups/developers
  - gidnumber: 1102
- - PUT
  - authz/the-account/annotations/group/developers
  - name: name
    value: Developers
    YAML
      end
    end
  end
end
