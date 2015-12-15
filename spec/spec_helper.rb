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

module MockAsset
  def self.included base
    base.module_eval do
      attr_reader :api, :record
    end
  end
  
  def initialize api, record
    @api = api
    @record = record
  end
end

class MockRole
  include MockAsset
  
  def role?; true; end
  
  def exists?
    !!@record
  end
end

class MockResource
  include MockAsset

  def exists?
    !!@record
  end
  
  def resource?; true; end
  
  def owner
    @record.owner || [ @api.account, 'group', 'operations' ].join(":")
  end
  
  def annotations
    (@record.annotations||{})
  end
end

class MockRecord
  include MockAsset
  
  def exists?
    !!@record
  end
  
  def attributes
    @record.custom_attribute_names.inject({}) do |memo,key|
      memo[key] = @record.send key
      memo
    end
  end
end

class MockAPI
  attr_reader :account, :records
  
  def initialize account, records
    @account = account
    @records = records
  end
  
  def resource id
    record = @records.find do |r|
      r.resource? && r.resourceid(account) == id
    end
    MockResource.new(self, record)
  end
  
  def role id
    role = @records.find do |r|
      r.role? && r.roleid(account) == id
    end
    MockRole.new(self, role)
  end
  
  def group id
    record = @records.find do |r|
      r.is_a?(Types::Group) && r.id == id
    end
    MockRecord.new self, record
  end

  def variable id
    record = @records.find do |r|
      r.is_a?(Types::Variable) && r.id == id
    end
    MockRecord.new self, record
  end
end
