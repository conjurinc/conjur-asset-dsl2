require 'spec_helper'
include Conjur::DSL2

describe "planning and execution" do
  let(:fixture) { YAML.load(File.read(filename), filename) }
  let(:conjur_state){ Conjur::DSL2::YAML::Loader.load(fixture['conjur']) }
  let(:policy) { Conjur::DSL2::YAML::Loader.load(fixture['policy']) }
  let(:exception) { fixture['exception'] }
  let(:planner) { Planner.planner_for(policy[0], api) }
  let(:api) { MockAPI.new 'the-account', conjur_state }
  let(:plan_actions) do
    plan = Plan.new
    planner.plan = plan
    begin
      planner.do_plan
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
      executor = Executor.class_for(statement).new(statement, actions, 'the-account')
      executor.execute
    end
    actions
  end
  let(:plan_yaml) do
    plan_actions.to_yaml
  end
  let(:execution_yaml) do
    execution_actions.to_yaml
  end
  before do
    require 'conjur/api'
    allow(Conjur).to receive(:configuration).and_return(double(:configuration, account: "the-account", authz_url: "https://conjur/api/authz"))
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
    it("matches execution YAML") {
      unless exception
        expect(execution_yaml).to eq(fixture['execution'])
      end
    }
  end
  
  fixtures_dir = File.expand_path("fixtures", File.dirname(__FILE__))
  Dir.chdir(fixtures_dir) do
    Dir['*.yml'].each do |file_example_name|
      describe file_example_name do
        let(:filename) { File.expand_path(file_example_name, fixtures_dir) }
        it_should_behave_like "verify plan"
        it_should_behave_like "verify execution"
      end
    end
  end
end
