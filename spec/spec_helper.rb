$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'conjur-asset-dsl2'

if ENV['DEBUG'] == 'true'
  Conjur::DSL2::Handler.logger.level = Logger::DEBUG
end

shared_context "planner" do
  let(:api) { double(:api) }
  before do
    allow(Conjur).to receive(:configuration).and_return double(:configuration, account: "the-account")
  end
  let(:records) { Ruby::Loader.load_file(filename) }
end