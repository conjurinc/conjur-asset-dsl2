
require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/features/'
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'conjur-asset-policy'
require 'logger'

if ENV['DEBUG']
  Conjur::Policy::YAML::Handler.logger.level = Logger::DEBUG 
  Conjur::Policy::Planner::Base.logger.level = Logger::DEBUG
  Conjur::Policy::Executor::Base.logger.level = Logger::DEBUG
end

Conjur::Policy::Planner::BaseFacts.sort = true

require 'semantic'

shared_context "planner", planning: true do
  let(:api) { double(:api) }
  before do
    require 'conjur/api'
    allow(Conjur).to receive(:configuration).and_return(double(:configuration, account: "the-account"))
  end
  let(:records) { Conjur::Policy::YAML::Loader.load_file(filename) }

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

  def roleid
    @record.try(:roleid)
  end

  def role?
    true
  end

  def exists?
    !!@record
  end
  
  # Note: Does not perform any role expansion. Just checks for equivalence, or if I am 
  # the owner of the role record.
  def can_admin_role? role
    return false unless exists?
    
    self.record.roleid == role.record.roleid || self.record.roleid == role.record.owner.roleid
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

  def resourceid
    @record.try(:resourceid)
  end

  def kind
    @record.class.short_name.underscore
  end

  def exists?
    !!@record
  end

  def resource?
    true;
  end

  def owner
    @record.owner.roleid || api.role("the-account:user:default-owner").record.roleid
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

  def resourceid
    @record.try(:resourceid)
  end

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

class MockUser < MockRecord
  def public_keys
    @record.public_keys
  end
end

class MockVariable < MockRecord
  def kind
    @record.kind || "secret"
  end
  
  def mime_type
    @record.mime_type || "text/plain"
  end
end

class MockAPI
  attr_reader :account, :records, :existing_resources, :show_admin_option
  alias :show_admin_option? :show_admin_option

  FOUR_EIGHT = Semantic::Version.new('4.8.0')
  def initialize account, records, conjur_version
    @account = account
    @records = records
    @existing_resources = @records.collect {|r| MockResource.new(self, r) if r.resource?}.compact
    @roles_by_id = { 'the-account:user:default-owner' => MockRole.new(self, Types::User.new('default-owner').tap{|u| u.account = 'the-account'}) }
    @resources_by_id = {}
    @records_by_id = {}
    @show_admin_option = Semantic::Version.new(conjur_version) >= FOUR_EIGHT
  end

  def current_role
    role 'the-account:user:default-owner'
  end

  def resources(options = {})
    existing_resources.select { |rsrc| !options[:kind] || rsrc.kind == options[:kind] }
  end

  def role_graph role
    admin_option = show_admin_option? ? true : nil
    @role_graph ||= Conjur::Graph.new(@records.select(&:role?).collect {|r| [r.roleid, r.owner.roleid, admin_option]})
  end

  def resource id
    find_or_create @resources_by_id, id do
      record = @records.find do |r|
        r.resource? && r.resourceid(account) == id
      end
      MockResource.new(self, record)
    end
  end

  def roles
    @roles_by_id.values
  end
  
  def role id
    find_or_create @roles_by_id, id do
      role = @records.find do |r|
        r.role? && r.roleid(account) == id
      end
      MockRole.new(self, role)
    end
  end

  def user id
    find_or_create_record Types::User, id
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
      cls = begin
        Object.const_get "Mock#{kind_class.simple_name}".classify
      rescue NameError
        MockRecord
      end
      cls.new self, record
    end
  end

  protected

  def find_or_create list, id
    result = list[id]
    return result if result
    list[id] = yield
  end
end
