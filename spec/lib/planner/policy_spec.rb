require 'spec_helper'
require 'conjur/dsl2/ruby/loader'
include Conjur::DSL2

describe Planner, planning: true do
  let(:filename) { "spec/lib/planner/policy_fixture.yml" }
  let(:empty_fixture){ Conjur::DSL2::YAML::Loader.load('[]') }
  let(:policy) { Planner.planner_for(records[0], api) }
  let(:api) { MockAPI.new 'the-account', fixture }

  context "when nothing exists" do
    let(:fixture) { empty_fixture }
    let(:subject) { policy }
    it "creates everything" do
      expect(plan_descriptions.sort).to eq([
        "Create policy role 'artifactory'",
        "Create policy resource 'artifactory'",
        "Create variable 'artifactory/username'",
        "Create variable 'artifactory/password'",
        "Create group 'artifactory/secrets-users'",
        "Permit group 'artifactory/secrets-users' to 'read' variable 'artifactory/username'",
        "Permit group 'artifactory/secrets-users' to 'execute' variable 'artifactory/username'",
        "Permit group 'artifactory/secrets-users' to 'read' variable 'artifactory/password'",
        "Permit group 'artifactory/secrets-users' to 'execute' variable 'artifactory/password'"
        ].sort)
      expect(plan_yaml).to eq(<<-YAML)
---
- !create
  record: !role
    id: artifactory
    kind: policy
- !create
  record: !resource
    id: artifactory
    kind: policy
    owner: !role
      id: artifactory
      kind: policy
- !create
  record: !group
    id: artifactory/secrets-users
    owner: !role
      id: artifactory
      kind: policy
- !create
  record: !variable
    id: artifactory/username
    owner: !role
      id: artifactory
      kind: policy
- !create
  record: !variable
    id: artifactory/password
    owner: !role
      id: artifactory
      kind: policy
- !permit
  privilege: read
  resource: !variable
    id: artifactory/username
  role: !member
    role: !group
      id: artifactory/secrets-users
- !permit
  privilege: execute
  resource: !variable
    id: artifactory/username
  role: !member
    role: !group
      id: artifactory/secrets-users
- !permit
  privilege: read
  resource: !variable
    id: artifactory/password
  role: !member
    role: !group
      id: artifactory/secrets-users
- !permit
  privilege: execute
  resource: !variable
    id: artifactory/password
  role: !member
    role: !group
      id: artifactory/secrets-users
            YAML
    end
  end
end
