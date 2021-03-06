require 'spec_helper'
require 'conjur/policy/planner/facts'
include Conjur::Policy::Planner

describe RoleFacts do
  MockExistingRole = Struct.new(:roleid) do
  end
  
  MockExistingGrant = Struct.new(:member) do
    def member
      MockExistingRole.new(self[:member].role.roleid)
    end
    def admin_option
      !!self[:member].admin
    end
  end
  
  let(:planner) { double(:planner) }
  let(:fixture) {
    YAML.load(File.read(filename), filename)
  }
  let(:existing_records) { Conjur::Policy::YAML::Loader.load(fixture['existing']) }
  let(:requested_records) { Conjur::Policy::YAML::Loader.load(fixture['requested']) }
  let(:role_facts) {
    RoleFacts.new(planner).tap do |facts|
      Conjur::Policy::Resolver.resolve(existing_records, "the-account", "the-account:user:the-owner", nil).each do |grant|
        Array(grant.role).each do |role|
          Array(grant.member).each do |member|
            facts.add_existing_grant MockExistingRole.new(role.roleid), MockExistingGrant.new(member)
          end
        end
      end
      Conjur::Policy::Resolver.resolve(requested_records, "the-account", "the-account:user:the-owner", nil).each do |grant|
        facts.add_requested_grant grant
      end
    end
  }
  let(:apply_expectation) {
    fixture['apply'].map do |record|
      [ 
        "the-account:#{record['role']}",
        "the-account:#{record['member']}",
        record['admin'] || false
      ]
    end.sort
  }
  let(:revoke_expectation) {
    fixture['revoke'].map do |record|
      [ 
        "the-account:#{record['role']}",
        "the-account:#{record['member']}"
      ]
    end.sort
  }
  let(:apply_list) { role_facts.grants_to_apply.to_a.sort }
  let(:revoke_list) { role_facts.grants_to_revoke.to_a.sort }

  shared_examples_for "verify apply list" do
    it("has the expected apply list") do
      expect(apply_list).to eq(apply_expectation)
    end
  end

  shared_examples_for "verify revoke list" do
    it("has the expected revoke list") do
      expect(revoke_list).to eq(revoke_expectation)
    end
  end

  fixtures_dir = File.expand_path("role-facts-fixtures", File.dirname(__FILE__))
  Dir.chdir(fixtures_dir) do
    files = if env = ENV['POLICY_FIXTURES']
      env.split(',')
    else
      Dir['*.yml']
    end

    files.each do |file_example_name|
      describe file_example_name do
        let(:filename) { File.expand_path(file_example_name, fixtures_dir) }
        it_should_behave_like "verify apply list"
        it_should_behave_like "verify revoke list"
      end
    end
  end
end