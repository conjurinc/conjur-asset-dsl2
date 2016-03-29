require 'spec_helper'
include Conjur::Policy

describe "planning and execution" do
  let(:fixture) { YAML.load(File.read(filename), filename) }
  let(:conjur_state){ Conjur::Policy::YAML::Loader.load(fixture['conjur'] || [].to_yaml) }
  let(:policy) { Conjur::Policy::YAML::Loader.load(fixture['policy']) }
  let(:account) { 'the-account' }
  let(:ownerid) { "#{account}:user:default-owner" }
  let(:namespace) { fixture['namespace'] }
  let(:records) { Conjur::Policy::Resolver.resolve policy, account, ownerid, namespace }
  let(:exception) { fixture['exception'] }
  let(:api) { MockAPI.new account, conjur_state }
  let(:plan_actions) do
    begin
      plan = Planner.plan records, api
      plan.actions
    rescue
      @exception = $!
      puts "EXCEPTION: #{$!}\n#{$@.join "\n\t"}"
      []
    end
  end
  let(:execution_actions) do
    actions = []
    plan_actions.each do |statement|
      executor = Executor.class_for(statement).new(statement, actions)
      executor.execute
    end
    actions
  end
  let(:plan_yaml) do
    Conjur::Policy::CompactOutputResolver.new(account, ownerid, namespace).resolve(plan_actions).to_yaml
  end
  let(:execution_yaml) do
    execution_actions.map do |action|
      # Remove 'ownerid' entries which match the default, in order to compact the test case fixtures.
      if parameters = action['parameters']
        parameters.delete('ownerid') if parameters['ownerid'] == ownerid
        parameters.delete('acting_as') if parameters['acting_as'] == ownerid
      end
      action
    end.to_yaml
  end
  before do
    require 'conjur/api'
    allow(Conjur).to receive(:configuration).and_return(double(:configuration, account: account, authz_url: "https://conjur/api/authz"))
  end
  
  shared_examples_for "verify plan" do
    it("matches plan exception") {
      if @exception
        expect(@exception.class.name).to eq(exception['class'])
        expect(@exception.message).to eq(exception['message'])
      end
    }
    it("matches plan YAML") {
      unless exception
        expect(plan_yaml).to eq(fixture['plan'])
      end
    }
    it("matches plan description") {
      unless exception
        expect(plan_actions.map(&:to_s).map(&:strip)).to eq(fixture['description'].map(&:strip)) unless fixture['description'].blank?
      end
    }
  end

  shared_examples_for "verify execution" do
    it("matches execution YAML") do
      if fixture['execution'] && !@exception
        expect(execution_yaml).to eq(fixture['execution'])
      end
      if @exception && fixture['execution']
        raise %Q(Unexpected exception: #{@exception}\n#{@exception.backtrace.join "\n  "})
      end
    end
  end
  
  fixtures_dir = File.expand_path("flow-fixtures", File.dirname(__FILE__))
  Dir.chdir(fixtures_dir) do
    files = if env = ENV['POLICY_FIXTURES']
      env.split(',')
    else
      Dir['*.yml']
    end

    files.each do |file_example_name|
      describe file_example_name do
        let(:filename) { File.expand_path(file_example_name, fixtures_dir) }
        it_should_behave_like "verify plan"
        it_should_behave_like "verify execution"
      end
    end
  end
end
