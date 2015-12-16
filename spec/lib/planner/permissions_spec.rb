require 'spec_helper'
require 'conjur/dsl2/ruby/loader'

include Conjur::DSL2

describe Planner::Permit, planning: true do
  
  let(:filename) { "spec/lib/planner/permissions_fixture.yml" }
  let(:permit) { records[0] }
  let(:planner) { Planner.planner_for(permit, api) }
  subject { planner }
    
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
          expect(plan_descriptions).to eq([
            "Permit group 'developers' to 'read' variable 'db-password'",
            "Permit group 'developers' to 'execute' variable 'db-password'"
            ])
          expect(plan_yaml).to eq(<<-YAML)
---
- !permit
  privilege: read
  resource: !variable
    id: db-password
  role: !member
    role: !group
      id: developers
- !permit
  privilege: execute
  resource: !variable
    id: db-password
  role: !member
    role: !group
      id: developers
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
          expect(plan_descriptions).to eq([
            "Permit group 'developers' to 'execute' variable 'db-password'",
            ])
        end
        context "and the permission is 'replace'" do
          before {
            permit.replace = true
          }
          it "permits it to the new role and denies to the existing role" do
            expect(plan_descriptions).to eq([
              "Deny group 'operations' to 'read' variable 'db-password'",
              "Permit group 'developers' to 'execute' variable 'db-password'",
              ])
            expect(plan_yaml).to eq(<<-YAML)
---
- !deny
  privilege: read
  resource: !variable
    id: db-password
  role: !group
    id: operations
- !permit
  privilege: execute
  resource: !variable
    id: db-password
  role: !member
    role: !group
      id: developers
            YAML
          end
        end
      end
    end
  end
end