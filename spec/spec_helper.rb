$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'conjur-asset-dsl2'
require 'logger'

if ENV['DEBUG']
  Conjur::DSL2::YAML::Handler.logger.level = Logger::DEBUG 
  Conjur::DSL2::Planner::Base.logger.level = Logger::DEBUG
  Conjur::DSL2::Executor::Base.logger.level = Logger::DEBUG
end

shared_context "planner", planning: true do
  let(:api) { double(:api) }
  before do
    require 'conjur/api'
    allow(Conjur).to receive(:configuration).and_return(double(:configuration, account: "the-account"))
  end
  let(:records) { Conjur::DSL2::YAML::Loader.load_file(filename) }

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

  def to_s
    record.to_s
  end

  def get
    raise RestClient::ResourceNotFound unless exists?
    attributes.to_json
  end
end

class MockRole
  include MockAsset

  def role?;
    true;
  end

  def exists?
    !!@record
  end

  def members
    api.role_members(record)
  end

  def attributes
    {}
  end
end

class MockResource
  include MockAsset


  def exists?
    !!@record
  end

  def resource?;
    true;
  end

  def owner
    @record.owner || ['the-account', 'user', 'default-owner'].join(":")
  end

  def annotations
    (@record.annotations||{})
  end

  def attributes
    @attributes ||= {
        'permissions' => @api.permissions(@record)
    }
  end

end

class MockRecord
  include MockAsset

  def exists?
    !!@record
  end

  def attributes
    @record.custom_attribute_names.inject({}) do |memo, key|
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
    @roles_by_id = {}
    @resources_by_id = {}
    @records_by_id = {}
  end

  def resource id
    find_or_create @resources_by_id, id do
      record = @records.find do |r|
        r.resource? && r.resourceid(account) == id
      end
      MockResource.new(self, record)
    end
  end

  def role id
    find_or_create @roles_by_id, id do
      role = @records.find do |r|
        r.role? && r.roleid(account) == id
      end
      MockRole.new(self, role)
    end
  end

  def group id
    find_or_create_record Types::Group, id
  end

  def layer id
    find_or_create_record Types::Layer, id
  end

  def host_factory id
    find_or_create_record Types::HostFactory, id
  end

  def variable id
    find_or_create_record Types::Variable, id
  end

  # called by MockRole#members
  def role_members role_record
    return [] if role_record.nil?
    roleid = role_record.roleid(account)
    [].tap do |members|
      @records.select{|r| r.kind_of?(Types::Grant)}.each do |record|
        Array(record.role).product(Array(record.member)).each do |role, member|
          next unless role.roleid(account) == roleid
          role_member = Conjur::Role.new(Conjur::Authz::API.host, {})[Conjur::API.parse_role_id(record.member.role.roleid(account)).join('/')]
          members << Conjur::RoleGrant.new(role_member, "role grantor", member.admin)
        end
      end
    end
  end

  def permissions resource_record
    return [] if resource_record.nil?
    permissions = []
    @records.each do |record|
      next unless record.kind_of?(Types::Permit)
      resources = Array(record.resource).select{|r| r.resourceid(account) == resource_record.resourceid(account)}
      Array(record.role).product(resources).product(Array(record.privilege)).each do |pair, priv|
        member, resource = pair
        role = member.role

        permissions.push({
          'role' => role.roleid(account),
          'resource' => resource.resourceid(account),
          'privilege' => priv,
          'grant_option' => !!member.admin
        })
      end
    end
    permissions
  end

  protected

  def find_or_create_record kind_class, id
    find_or_create @records_by_id, [kind_class.short_name.underscore, id].join(":") do
      record = @records.find do |r|
        r.is_a?(kind_class) && r.id == id
      end
      MockRecord.new self, record
    end
  end

  protected

  def find_or_create list, id
    result = list[id]
    return result if result
    list[id] = yield
  end
end
