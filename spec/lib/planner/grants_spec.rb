require 'spec_helper'
require 'conjur/dsl2/ruby/loader'

include Conjur::DSL2

describe Planner, planning: true do
  let(:filename) { "spec/lib/planner/grants_fixture.rb" }
  let(:api) { MockAPI.new 'the-account', fixture }
  let(:grant_record) { records[0] }
  let(:grant_plan) { Planner.planner_for(grant_record, api) }
  subject { grant_plan }
    
  context "when the grant is brand new" do
    let(:fixture) {
      Conjur::DSL2::YAML::Loader.load <<-YAML
[]
      YAML
    }
    context "when the role does not exist" do
      it "reports the error"
    end
    context "when the member does not exist" do
      it "reports the error"
    end
    context "when the role and member exist" do
      let(:fixture) {
        Conjur::DSL2::YAML::Loader.load <<-YAML
- !role
  kind: group
  id: secrets-managers
- !role
  kind: group
  id: secrets-users
        YAML
      }
      context "and the role has no grants existing" do
        it "grants it to all roles" do
          expect(plan_descriptions).to eq(["Grant group 'secrets-users' to group 'secrets-managers'"])
          expect(plan_yaml).to eq(<<-YAML)
---
- !grant
  member: !member
    role: !group
      id: secrets-managers
  role: !group
    id: secrets-users
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
        before {
          expect(api.role("the-account:group:secrets-users")).to receive(:members).and_return(members)
        }
        it "permits it to the new role" do
          expect(plan_descriptions).to eq(["Grant group 'secrets-users' to group 'secrets-managers'"])
        end
        context "with 'replace'" do
          before {
            grant_record.replace = true
          }
          it "permits it to the new role and revokes the existing non-admin role" do
            expect(plan_descriptions).to eq(["Grant group 'secrets-users' to group 'secrets-managers'",
              "Revoke group 'secrets-users' from group 'developers'"])
            expect(plan_yaml).to eq(<<-YAML)
---
- !grant
  member: !member
    role: !group
      id: secrets-managers
  role: !group
    id: secrets-users
- !revoke
  member: !group
    id: developers
  role: !group
    id: secrets-users
            YAML
          end
        end
      end
    end
  end
end
