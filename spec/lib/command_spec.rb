require 'spec_helper'
require 'conjur/cli'
require 'conjur/command/rspec/describe_command'
require 'conjur/command/rspec/output_matchers'

POLICY_FIXTURE_FILE = "#{File.dirname(__FILE__)}/round-trip/yaml/org.yml"
PLAN_FIXTURE_FILE = "#{File.dirname(__FILE__)}/import/import.yml"

describe Conjur::Command::Policy do
  let(:account) { "cucumber" }
  let(:ownerid) { "#{account}:user:alice" }
  let(:api) { double(:api, username: "alice") }
  let(:records){ double(:records) }
  let(:loader){ Conjur::Policy::YAML::Loader }
  let(:resolver){ Conjur::Policy::YAML::Resolver }
  let(:plan){ double(:plan, actions: ['action']) }
  let(:namespace) { nil }

  shared_examples_for "execute the plan" do
    it 'loads the plan and executes the actions' do
      expect(described_class).to receive(:execute).with(api, plan.actions)
      invoke
    end
  end

  before do
    allow(described_class).to receive(:api).and_return api
    allow(loader).to receive(:load).with(
        File.read(POLICY_FIXTURE_FILE),
        POLICY_FIXTURE_FILE).and_return records
    allow(Conjur::Policy::Resolver).to receive(:resolve).with(records, account, ownerid, namespace).and_return records
    allow(Conjur::Policy::Planner).to receive(:plan).with(records, api).and_return plan
  end

  describe_command "policy load --namespace foo #{POLICY_FIXTURE_FILE}" do
    let(:namespace) { "foo" }
    it_should_behave_like "execute the plan"
  end

  describe_command "policy load --namespace foo --context conjur.json #{POLICY_FIXTURE_FILE}" do
    let(:namespace) { "foo" }
    let(:context_hash){
      { 'foo' => 'bar', 'x' => 'y' }
    }

    let(:expected_context_json){
      context_hash.to_json
    }

    before do
      allow(File).to receive(:file?).with('conjur.json').and_return context_exists
      allow(File).to receive(:read).with('conjur.json').and_return context_content
      allow(File).to receive(:read).with(POLICY_FIXTURE_FILE).and_call_original
      allow(described_class).to receive(:execute).with(api, plan.actions).and_return context_hash
    end

    context 'when the context file does not exist' do
      let(:context_exists){ false }
      let(:context_content){ "" }

      it 'writes the new file with API keys' do
        expect(File).to receive(:write).with('conjur.json', expected_context_json)
        invoke
      end
    end

    context 'when the context file exists and contains an api key for baz and foo' do
      let(:context_exists){ true }
      let(:existing_context){  {'foo' => 'blah', 'baz' => 'qux'} }
      let(:context_content){ existing_context.to_json }
      let(:expected_context_json){
        existing_context.merge(context_hash).to_json
      }
      it 'merges the new api keys into the file' do
        expect(File).to receive(:write).with('conjur.json', expected_context_json)
        invoke
      end
    end

    context 'when File.write raises an exception' do
      let(:context_exists){ false }
      let(:context_content){ '' }
      it 'writes the context to the stdout' do
        allow(File).to receive(:write).with('conjur.json', expected_context_json) do
          raise "BOOM"
        end

        expect{ invoke }.to write(expected_context_json)
      end
    end
  end

  describe_command "policy import #{PLAN_FIXTURE_FILE}" do
    before do
      allow(Conjur::Policy::YAML::Loader).to receive(:load).with(
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
