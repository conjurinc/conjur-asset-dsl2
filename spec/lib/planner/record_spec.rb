require 'spec_helper'
require 'conjur/dsl2/ruby/loader'
include Conjur::DSL2

describe Planner, planning: true do
  let(:filename) { "spec/lib/planner/record_fixture.yml" }
  let(:empty_fixture){ Conjur::DSL2::YAML::Loader.load('[]') }
  let(:simple_group) { Planner.planner_for(records[0], api) }
  let(:group_with_attributes) { Planner.planner_for(records[1], api) }
  let(:group_with_new_owner) { Planner.planner_for(records[6], api) }
  let(:simple_role){ Planner.planner_for(records[3], api) }
  let(:variable){ Planner.planner_for(records[2], api) }
  let(:resource_with_annotation){ Planner.planner_for(records[4], api) }
  let(:layer){ Planner.planner_for(records[7], api) }
  let(:host_factory){ Planner.planner_for(records[8], api) }
  let(:api) { MockAPI.new 'the-account', fixture }

  context "when group doesn't exist" do
    let(:fixture) { empty_fixture }
    let(:subject) { simple_group }
    it "creates a group" do
      expect(plan_descriptions).to eq([
                  "Create group 'developers'"
              ])
      expect(plan_yaml).to eq(<<-YAML)
---
- !create
  record: !group
    id: developers
      YAML
    end
  end

  context "when group exists" do
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
    context "with a different owner changes" do
      let(:subject) { group_with_new_owner }
      it "changes the owner" do
        expect(plan_descriptions).to eq(["Give group 'developers' to group 'operations' in account 'foreign-account'", 
          "Grant group 'developers' to group 'operations' in account 'foreign-account' with admin option"])
        expect(plan_yaml).to eq(<<-YAML)
---
- !give
  owner: !role
    account: foreign-account
    id: operations
    kind: group
  resource: !resource
    id: developers
    kind: group
- !grant
  member: !member
    admin: true
    role: !role
      account: foreign-account
      id: operations
      kind: group
  role: !role
    id: developers
    kind: group
        YAML
      end
    end
  end

  describe 'role creation' do
    context 'when the role does not exist' do
      let(:fixture){ empty_fixture }
      subject{ simple_role }

      it 'creates the role' do
        expect(plan_descriptions).to eq(["Create job 'cook'"])
        expect(plan_yaml).to eq(<<-YAML)
---
- !create
  record: !role
    id: cook
    kind: job
        YAML
      end

    end

    context 'when the role exists' do
      let(:fixture){
        Conjur::DSL2::YAML::Loader.load <<-YAML
---
- !role
  kind: job
  id: cook
        YAML
      }
      subject{ simple_role }

      it 'does nothing' do
        expect(plan_descriptions).to be_empty
        expect(plan_yaml).to eq([].to_yaml)
      end

    end
  end

  describe 'resource creation' do
    subject{ resource_with_annotation }
    context 'when the resource does not exist' do
      let(:fixture){ empty_fixture }
      it 'creates the resource and annotates it' do
        expect(plan_descriptions).to eq(["Create food 'bacon'\n\tSet annotation 'tastes'"])
        expect(plan_yaml).to eq(<<-YAML)
---
- !create
  record: !resource
    annotations:
      tastes: Yummy
    id: bacon
    kind: food
        YAML
      end
    end

    context 'when the resource exists but does not have any annotations' do
      let(:fixture){
        Conjur::DSL2::YAML::Loader.load <<-YAML
- !resource
  kind: food
  id: bacon
        YAML
      }
      it 'updates the resource with the annotation' do
        expect(plan_descriptions).to eq(["Update food 'bacon'\n\tSet annotation 'tastes'"])
        expect(plan_yaml).to eq(<<-YAML)
---
- !update
  record: !resource
    annotations:
      tastes: Yummy
    id: bacon
    kind: food
        YAML
      end
    end

    context 'when the resource exists and has the annotation' do
      let(:fixture){
        Conjur::DSL2::YAML::Loader.load <<-YAML
- !resource
  kind: food
  id: bacon
  annotations:
    tastes: Yummy
        YAML
      }

      it 'does nothing' do
        expect(plan_descriptions).to be_empty
        expect(plan_yaml).to eq([].to_yaml)
      end
    end
  end

  describe 'variable records' do
    subject{ variable }

    context 'when the variable does not exist' do
      let(:fixture){ empty_fixture }
      it 'creates it' do
        expect(plan_descriptions).to eq( ["Create variable 'db-password'"])
        expect(plan_yaml).to eq(<<-YAML)
---
- !create
  record: !variable
    id: db-password
    kind: database password
        YAML
      end
    end

    context 'when the variable exists and has the same kind' do
      let(:fixture){
        Conjur::DSL2::YAML::Loader.load <<-YAML
- !variable
  id: db-password
  kind: database password
        YAML
      }

      it 'does nothing' do
        expect(plan_descriptions).to be_empty
        expect(plan_yaml).to eq([].to_yaml)
      end
    end

    context 'when the variable exists and has different kind' do
      let(:fixture){
        Conjur::DSL2::YAML::Loader.load <<-YAML
- !variable
  id: db-password
  kind: generic password
        YAML
      }

      it 'fails' do
        expect{ plan_descriptions }.to raise_error(RuntimeError, /Cannot modify immutable attribute.*/)
      end
    end

    context 'when the variable exists and has a different mime_type' do
      let(:fixture){
        Conjur::DSL2::YAML::Loader.load <<-YAML
- !variable
  id: db-password
  kind: generic password
  mime_type: whatever
        YAML
      }

      it 'fails' do
        expect{ plan_descriptions }.to raise_error(RuntimeError, /Cannot modify immutable attribute.*/)
      end
    end
  end

  describe 'host factory' do
    subject{ host_factory }

    context 'when it does not exist' do
      let(:fixture){ empty_fixture }
      it 'creates it' do
        expect(plan_descriptions).to eq( ["Create host factory 'frontend'"])
        expect(plan_yaml).to eq(<<-YAML)
---
- !create
  record: !host-factory
    id: frontend
    layer: !layer
      id: frontend
    role: !group
      id: dev-admin
        YAML
      end
    end
  end
end
