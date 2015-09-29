require 'spec_helper'
require 'conjur/dsl2/loader'

describe Conjur::DSL2::DryRunExecutor do
  context "group.yml" do
    let(:filename) { "spec/lib/executor/group.yml" }
    let(:records) { Conjur::DSL2::Loader.load_file(filename) }
    let(:subject) { Conjur::DSL2::DryRunExecutor.new(records) }
    it "creates two groups" do
      subject.execute
      expect(subject.actions.to_yaml).to eq(<<-YAML)
---
- - :kind: :group
    :id: developers
    :options: {}
    :annotations: {}
- - :kind: :group
    :id: operations
    :options:
      :gidnumber: 1001
    :annotations:
      name: Operations
      YAML
    end
  end
end