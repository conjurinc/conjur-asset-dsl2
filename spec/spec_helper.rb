$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'conjur-asset-dsl2'

if ENV['DEBUG'] == 'true'
  Conjur::DSL2::Handler.logger.level = Logger::DEBUG
end

shared_context "planner", planning: true do
  let(:api) { double(:api) }
  before do
    require 'conjur/api'
    allow(Conjur).to receive(:configuration).and_return(double(:configuration, account: "the-account"))
  end
  let(:records) { Ruby::Loader.load_file(filename) }
    
  subject { planner }
    
  let(:plan_actions) do
    plan = Plan.new
    subject.plan = plan
    subject.do_plan
    plan.actions
  end
    
  let(:plan_yaml) do
    plan_actions.to_yaml
  end
  
  let(:plan_descriptions) do
    plan_actions.map(&:to_s)
  end
end
