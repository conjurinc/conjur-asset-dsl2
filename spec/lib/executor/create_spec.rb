require 'spec_helper'
require 'conjur/dsl2/ruby/loader'

include Conjur::DSL2

describe Executor, planning: true do
  let(:plan) { Planner.plan(records, api) }
  let(:actions) { [] }
  let(:executor) { executor_class.new record, actions, 'the-account' }
  let(:nothing) { double(:nothing, exists?: false) }
  let(:api) { double(:api, group: nothing, variable: nothing, role: nothing, resource: nothing) }

  before {
    executor.execute
  }
  
  shared_examples_for "proper HTTP request" do
    it do
      expect(actions.map(&:symbolize_keys)).to eq(requests)
    end
  end
  
  describe Executor::Create do
    let(:filename) { "spec/lib/executor/create_fixture.yml" }
    let(:executor_class) { Executor.creator_class_for record }
    let(:group) { plan.actions[0] }
    let(:variable) { plan.actions[1] }
    let(:role) { plan.actions[2] }
    let(:resource) { plan.actions[3] }
      
    describe "group" do
      let(:record) { group }
      let(:requests) { [{method: "post", path: "groups", parameters: {"id"=>"developers", "gidnumber"=>1102}}] }
      it_should_behave_like "proper HTTP request"
    end
    describe "variable" do
      let(:record) { variable }
      let(:requests) { [{method: "post", path: "variables", parameters: {"id"=>"db-password", "mime_type" => "text/plain", "kind"=>"database password"}}] }
      it_should_behave_like "proper HTTP request"
    end
    describe "role" do
      let(:record) { role }
      let(:requests) { [{method: "put", path: "authz/the-account/roles/job/cook", parameters: {}}] }
      it_should_behave_like "proper HTTP request"
    end
    describe "resource" do
      let(:record) { resource }
      let(:requests) { [{method: "put", path: "authz/the-account/resources/food/bacon", parameters: {}}] }
      it_should_behave_like "proper HTTP request"
    end
  end
end
