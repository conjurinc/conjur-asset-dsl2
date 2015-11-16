require 'spec_helper'
require 'conjur/dsl2/ruby/loader'

include Conjur::DSL2

describe Planner::Grant do
  include_context "planner"
  
  let(:filename) { "spec/lib/planner/grants_fixture.rb" }
  let(:grant) { records[0] }
  let(:planner) { Planner.planner_for(grant, api) }
    
  let(:secrets_users_role) {
    double(:secrets_users_role, 
      exists?: secrets_users_exists, 
      kind: "group", 
      role_id: "secrets-users",
      members: members)
  }
  let(:members) { [] }
    
  let(:secrets_users_exists) { true }
    
  subject { planner }
    
  let(:plan_yaml) do
    plan = Plan.new
    subject.plan = plan
    subject.do_plan
    plan.actions.to_yaml
  end

  before do
    allow(api).to receive(:role).with("the-account:group:secrets-users").and_return secrets_users_role
  end

  context "when the grant is brand new" do
    context "when the role does not exist" do
      it "reports the error"
    end
    context "when the member does not exist" do
      it "reports the error"
    end
    context "when the role and member exist" do
      context "and the role has no grants existing" do
        it "grants it to all roles" do
          expect(plan_yaml).to eq(<<-YAML)
---
- service: authz
  type: role
  method: put
  action: grant
  path: authz/the-account/roles/group/secrets-users?members
  parameters:
    member: the-account:group:secrets-managers
    admin_option: false
  description: Grant the-account:group:secrets-users to the-account:group:secrets-managers
          YAML
        end
      end
      context "and the role has grants existing" do
        let(:grantor) { double(:grantor) }
        let(:members) {
          require 'conjur/api'
          [
            Conjur::RoleGrant.new(double(:developers, roleid: "the-account:group:developers"), grantor, false),
            Conjur::RoleGrant.new(double(:operations, roleid: "the-account:group:operations"), grantor, true),
          ]
        }
        it "permits it to the new role" do
          expect(plan_yaml).to eq(<<-YAML)
---
- service: authz
  type: role
  method: put
  action: grant
  path: authz/the-account/roles/group/secrets-users?members
  parameters:
    member: the-account:group:secrets-managers
    admin_option: false
  description: Grant the-account:group:secrets-users to the-account:group:secrets-managers
          YAML
        end
        context "with 'replace'" do
          before {
            grant.replace = true
          }
          it "permits it to the new role and revokes the existing non-admin role" do
            expect(plan_yaml).to eq(<<-YAML)
---
- service: authz
  type: role
  method: put
  action: grant
  path: authz/the-account/roles/group/secrets-users?members
  parameters:
    member: the-account:group:secrets-managers
    admin_option: false
  description: Grant the-account:group:secrets-users to the-account:group:secrets-managers
- service: authz
  type: role
  method: delete
  action: revoke
  path: authz/the-account/roles/group/secrets-users?members
  parameters:
    member: the-account:group:developers
  description: Revoke the-account:group:secrets-users from the-account:group:developers
            YAML
          end
        end
      end
    end
  end
end