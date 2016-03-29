require 'spec_helper'
require 'conjur/policy/planner/facts'
include Conjur::Policy::Planner

describe PrivilegeFacts do
  before {
    require 'conjur/api'
    allow(Conjur.configuration).to receive(:account).and_return("the-account")
  }
  let(:planner) { double(:planner) }
  let(:fixture) {
    YAML.load(File.read(filename), filename)
  }
  let(:existing_records) { Conjur::Policy::YAML::Loader.load(fixture['existing']) }
  let(:requested_records) { Conjur::Policy::YAML::Loader.load(fixture['requested']) }
  let(:privilege_facts) {
    PrivilegeFacts.new(planner).tap do |facts|
      Conjur::Policy::Resolver.resolve(existing_records, "the-account", "the-account:user:the-owner", nil).each do |permission|
        Array(permission.role).each do |member|
          Array(permission.privilege).each do |privilege|
            Array(permission.resource).each do |resource|
              puts [ member.to_s, privilege.to_s, resource.to_s].join(" ") if ENV['DEBUG']
              facts.add_existing_permission 'role' => member.role.roleid, 'privilege' => privilege, 'resource' => resource.resourceid, 'grant_option' => !!member.admin
            end
          end
        end
      end
      Conjur::Policy::Resolver.resolve(requested_records, "the-account", "the-account:user:the-owner", nil).each do |grant|
        puts grant.to_s if ENV['DEBUG']
        facts.add_requested_permission grant
      end
      p facts if ENV['DEBUG']
    end
  }
  let(:apply_expectation) {
    fixture['apply'].map do |record|
      [ 
        "the-account:#{record['role']}",
        record['privilege'],
        "the-account:#{record['resource']}",
        record['admin'] || false
      ]
    end.sort
  }
  let(:revoke_expectation) {
    fixture['revoke'].map do |record|
      [ 
        "the-account:#{record['role']}",
        record['privilege'],
        "the-account:#{record['resource']}"
      ]
    end.sort
  }
  let(:apply_list) { privilege_facts.grants_to_apply.to_a.sort }
  let(:revoke_list) { privilege_facts.grants_to_revoke.to_a.sort }

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

  fixtures_dir = File.expand_path("privilege-facts-fixtures", File.dirname(__FILE__))
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