require 'spec_helper'
require 'conjur/dsl2/ruby/loader'

include Conjur::DSL2::Ruby

describe Loader do
  shared_examples_for "round-trip" do |example|
    let(:source) { "spec/lib/round-trip/ruby/#{example}.rb" }
    let(:fixture) { "spec/lib/round-trip/ruby/#{example}.yml" }
    it "#{example}.rb" do
      Conjur::DSL2::Ruby::Loader.create(source).load(target)
      expect(target.to_yaml).to eq(File.read(fixture))
    end
  end
  
  describe Policy do
    let(:target) { Policy.new }
    it_should_behave_like 'round-trip', 'policy'
  end
  describe Entitlements do
    let(:target) { Entitlements.new }
    it_should_behave_like 'round-trip', 'sequence'
    it_should_behave_like 'round-trip', 'permissions'
    it_should_behave_like 'round-trip', 'grants'
    it_should_behave_like 'round-trip', 'records'
  end
end
