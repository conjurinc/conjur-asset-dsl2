require 'spec_helper'
require 'conjur/dsl2/ruby/loader'

include Conjur::DSL2

describe Planner::Permit do
  include_context "planner"
  
  let(:filename) { "spec/lib/planner/permissions_fixture.rb" }
  let(:permit) { records[0] }
  let(:planner) { Planner.planner_for(permit, api) }
    
  let(:db_password) { double(:db_password, exists?: db_password_exists) }
  let(:developers) { double(:developers, exists?: developers_exists) }
  let(:db_password_resource) {
    double(:db_password_resource, 
      exists?: db_password_exists, 
      kind: "variable", 
      resource_id: "db-password",
      get: { "id" => "cucumber:variable:db-password", "permissions" => permissions }.to_json)
  }
  let(:developers_resource) { double(:developers_resource, exists?: developers_exists) }
  let(:permissions) { [] }
    
  let(:db_password_exists) { true }
  let(:developers_exists) { true }
    
  subject { planner }
    
  let(:plan_yaml) do
    plan = Plan.new
    subject.plan = plan
    subject.do_plan
    plan.actions.to_yaml
  end

  before do
    allow(api).to receive(:resource).with("the-account:variable:db-password").and_return db_password_resource
    allow(api).to receive(:resource).with("the-account:group:developers").and_return developers_resource
  end

  context "when the permission is brand new" do
    context "when the role does not exist" do
      it "reports the error"
    end
    context "when the resource does not exist" do
      it "reports the error"
    end
    context "when the role and resource exist" do
      context "and the resource has no permissions existing" do
        it "permits it to all roles" do
          expect(plan_yaml).to eq(<<-YAML)
---
- service: authz
  type: resource
  method: post
  action: permit
  path: authz/the-account/resources/variable/db-password?permit
  parameters:
    privilege: read
    role: the-account:group:developers
    grant_option: false
  description: Permit the-account:group:developers to 'read' the-account:variable:db-password
- service: authz
  type: resource
  method: post
  action: permit
  path: authz/the-account/resources/variable/db-password?permit
  parameters:
    privilege: execute
    role: the-account:group:developers
    grant_option: false
  description: Permit the-account:group:developers to 'execute' the-account:variable:db-password
          YAML
        end
      end
      context "and the resource has permissions existing" do
        let(:permissions) {
          [
            {
              "privilege" => "read",
              "grant_option" => false,
              "resource" => "the-account:variable:db-password",
              "role" => "the-account:group:developers",
            },
            {
              "privilege" => "read",
              "grant_option" => false,
              "resource" => "the-account:variable:db-password",
              "role" => "the-account:group:operations",
            },
            {
              "privilege" => "update",
              "grant_option" => false,
              "resource" => "the-account:variable:db-password",
              "role" => "the-account:group:developers",
            }
          ]
        }
        it "permits it to the new role" do
          expect(plan_yaml).to eq(<<-YAML)
---
- service: authz
  type: resource
  method: post
  action: permit
  path: authz/the-account/resources/variable/db-password?permit
  parameters:
    privilege: execute
    role: the-account:group:developers
    grant_option: false
  description: Permit the-account:group:developers to 'execute' the-account:variable:db-password
          YAML
        end
        context "and the permission is 'replace'" do
          before {
            permit.replace = true
          }
          it "permits it to the new role and revokes the existing role" do
            expect(plan_yaml).to eq(<<-YAML)
---
- service: authz
  type: resource
  method: post
  action: deny
  path: authz/the-account/resources/variable/db-password?deny
  parameters:
    privilege: read
    role: the-account:group:operations
  description: Deny the-account:group:operations to 'read' the-account:variable:db-password
- service: authz
  type: resource
  method: post
  action: permit
  path: authz/the-account/resources/variable/db-password?permit
  parameters:
    privilege: execute
    role: the-account:group:developers
    grant_option: false
  description: Permit the-account:group:developers to 'execute' the-account:variable:db-password
            YAML
          end
        end
      end
    end
  end
end