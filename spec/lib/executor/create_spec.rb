require 'spec_helper'
require 'conjur/dsl2/ruby/loader'

include Conjur::DSL2

describe Executors::Record do
  context "group.yml" do
    let(:filename) { "spec/lib/executor/create_fixture.rb" }
    # let(:entitlements) { Ruby::Entitlements.new }
    # let(:records) { entitlements.first }
    let(:group) { double(:group, exists?: group_exists, gidnumber: 1101) }
    let(:variable) { double(:variable, exists?: variable_exists, mime_type: "text/plain", kind: "secret") }
    let(:group_resource) { double(:resource, owner: "the-account:group:developers", annotations: {}) }
    let(:variable_resource) { double(:resource, owner: "the-account:variable:db-password", annotations: {}) }
    let(:api) { double(:api) }
    let(:simple_group) { Executors::Record.new(records[0], api) }
    let(:group_with_attributes) { Executors::Record.new(records[1], api) }
    let(:simple_variable) { Executors::Record.new(records[2], api) }
    let(:subject) { simple_group }

    let(:group_exists) { false }
    let(:variable_exists) { false }

    attr_reader :records

    before do
      allow(Conjur).to receive(:configuration).and_return double(:configuration, account: "the-account")
    end
      
    before do
      @records = Ruby::Loader.create(filename).load
      allow(api).to receive(:group).with("developers").and_return group
      allow(api).to receive(:variable).with("db-password").and_return variable
      allow(api).to receive(:resource).with("the-account:group:developers").and_return group_resource
      allow(api).to receive(:resource).with("the-account:variable:db-password").and_return variable_resource
    end
    
    context "when group doesn't exist" do
      it "creates a group" do
        expect(subject.create.to_yaml).to eq(<<-YAML)
---
- - POST
  - groups
  - id: developers
        YAML
      end
    end
    context "when variable doesn't exist" do
      let(:subject) { simple_variable }
      it "creates a variable" do
        expect(subject.create.to_yaml).to eq(<<-YAML)
---
- - POST
  - variables
  - id: db-password
    kind: database password
        YAML
      end
    end
    context "when variable exists" do
      let(:subject) { simple_variable }
      let(:variable_exists) { true }
      it "mime_type is immutable" do
        expect { subject.create.to_yaml }.to raise_error("Cannot modify immutable attribute 'variable.kind'")
      end
    end
    context "when group exists" do
      let(:group_exists) { true }
      it "it can be a nop" do
        expect(subject.create.to_yaml).to eq(<<-YAML)
--- []
      YAML
      end
      context "and has attributes" do
        let(:subject) { group_with_attributes }
        it "it will update gidnumber and annotations" do
          expect(subject.create.to_yaml).to eq(<<-YAML)
---
- - PUT
  - groups/developers
  - gidnumber: 1102
- - PUT
  - authz/the-account/annotations/group/developers
  - name: name
    value: Developers
      YAML
        end
      end
    end
  end
end