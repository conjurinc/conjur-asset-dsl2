require 'spec_helper'
require 'conjur/cli'
require 'conjur/command/rspec/describe_command'
require 'conjur/command/rspec/output_matchers'

DSL2_FIXTURE_FILE = "#{File.dirname(__FILE__)}/round-trip/yaml/org.yml"
PLAN_FIXTURE_FILE = "#{File.dirname(__FILE__)}/import/import.yml"

describe Conjur::Command::DSL2 do
  let(:api) { double(:api) }
  let(:records){ double(:records) }
  let(:loader){ Conjur::DSL2::YAML::Loader }
  let(:plan){ double(:plan, actions: ['action']) }

  before do
    allow(described_class).to receive(:api).and_return api
    allow(loader).to receive(:load).with(
        File.read(DSL2_FIXTURE_FILE),
        DSL2_FIXTURE_FILE).and_return records
  end

  describe_command "policy2 load --namespace foo #{DSL2_FIXTURE_FILE}" do
    it 'loads the plan and executes the actions' do
      expect(Conjur::DSL2::Planner).to receive(:plan).with(records, api, {namespace: 'foo'}).and_return plan
      expect(described_class).to receive(:execute).with(api, plan.actions)
      invoke
    end
  end

  describe_command "policy2 load --namespace foo --context conjur.json #{DSL2_FIXTURE_FILE}" do

    let(:context_hash){
      { 'foo' => 'bar', 'x' => 'y' }
    }

    let(:expected_context_json){
      context_hash.to_json
    }

    before do
      allow(File).to receive(:file?).with('conjur.json').and_return context_exists
      allow(File).to receive(:read).with('conjur.json').and_return context_content
      allow(File).to receive(:read).with(DSL2_FIXTURE_FILE).and_call_original
      allow(Conjur::DSL2::Planner).to receive(:plan).with(records, api, {namespace: 'foo'}).and_return plan
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
