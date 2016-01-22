require 'spec_helper'
require 'conjur/cli'
require 'conjur/command/rspec/describe_command'
DSL2_FIXTURE_FILE = "#{File.dirname(__FILE__)}/round-trip/yaml/org.yml"
PLAN_FIXTURE_FILE = "#{File.dirname(__FILE__)}/import/import.yml"

describe Conjur::Command::DSL2 do
  let(:api) { double(:api) }
  before do
    allow(described_class).to receive(:api).and_return api
  end
  describe_command "policy2 load --namespace foo #{DSL2_FIXTURE_FILE}" do
    let(:records){ double(:records) }
    let(:loader){ Conjur::DSL2::YAML::Loader }
    let(:plan){ double(:plan, actions: ['action']) }
    let(:api) { double(:api) }
    before do
      allow(loader).to receive(:load).with(
          File.read(DSL2_FIXTURE_FILE),
          DSL2_FIXTURE_FILE).and_return records
    end

    it 'loads the plan and executes the actions' do
      expect(Conjur::DSL2::Planner).to receive(:plan).with(records, api, {namespace: 'foo'}).and_return plan
      expect(described_class).to receive(:execute).with(api, plan.actions)
      invoke
    end
  end

  describe_command "policy2 import #{PLAN_FIXTURE_FILE}" do
    before do
      allow(Conjur::DSL2::YAML::Loader).to receive(:load).with(
          File.read(PLAN_FIXTURE_FILE),
          PLAN_FIXTURE_FILE).and_return actions
    end
    let(:actions){ ['action1', 'action2'] }
    it 'loads the plan and executes it' do
      expect(described_class).to receive(:execute).with(api,actions,{})
      invoke
    end

  end
end
