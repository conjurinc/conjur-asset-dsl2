require 'spec_helper'
require 'conjur/dsl2/ruby/loader'

include Conjur::DSL2

describe Planner::Permit, planning: true do

  let(:filename) { "spec/lib/planner/permissions_fixture.yml" }
  let(:permit) { Planner.planner_for(records[0], api) }
  let(:api) { MockAPI.new 'the-account', fixture }

  let(:yaml_fixtures){ [] }
  let(:fixture_yaml){ yaml_fixtures.join "\n" }

  let(:fixture){
    Conjur::DSL2::YAML::Loader.load(fixture_yaml, filename)
  }

  shared_context 'role exists' do
    before { yaml_fixtures << '- !group developers' }
  end

  shared_context 'resource exists' do
    before { yaml_fixtures << '- !variable db-password' }
  end

  subject{ permit }

  context "when the permission is brand new" do
    context "when the role does not exist" do
      include_context 'resource exists'

      it "reports the error" do
        expect{ plan_descriptions }.to raise_error(RuntimeError, /role not found.*/i)
      end
    end

    context "when the resource does not exist" do
      include_context 'role exists'
      it "reports the error" do
        expect{ plan_descriptions }.to raise_error(RuntimeError, /resource not found.*/i)
      end
    end

    context "when the role and resource exist" do
      include_context 'role exists'
      include_context 'resource exists'
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
              "privilege" => "update",
              "grant_option" => false,
              "resource" => "the-account:variable:db-password",
              "role" => "the-account:group:developers",
            },
            {
                'privilege' => 'read',
                'grant_option' => false,
                'resource' => 'the-account:variable:db-password',
                'role'  => 'the-account:group:operations'
            }
          ]
        }

        before do
          api.resource('the-account:variable:db-password').attributes['permissions'] = permissions
        end

        it "permits it to the new role" do
          expect(plan_descriptions).to eq([
            "Permit group 'developers' to 'execute' variable 'db-password'",
            ])
        end

        context "and the permission is 'replace'" do
          before {
            permit.record.replace = true
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