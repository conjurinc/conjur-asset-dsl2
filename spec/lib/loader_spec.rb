require 'spec_helper'
require 'conjur/dsl2/loader'

describe Conjur::DSL2::Loader do
  shared_examples_for "round-trip dsl" do |example|
    let(:filename) { "spec/lib/#{example}.yml" }
    it "#{example}.yml" do
      expect(Conjur::DSL2::Loader.load_file(filename).to_yaml).to eq(File.read("spec/lib/#{example}.expected.yml"))
    end
  end
  
  before {
  }
  
  it_should_behave_like 'round-trip dsl', 'sequence'
  it_should_behave_like 'round-trip dsl', 'record'
  it_should_behave_like 'round-trip dsl', 'members'
  it_should_behave_like 'round-trip dsl', 'permit'
  it_should_behave_like 'round-trip dsl', 'permissions'
  it_should_behave_like 'round-trip dsl', 'deny'
  it_should_behave_like 'round-trip dsl', 'jenkins-policy'
end
