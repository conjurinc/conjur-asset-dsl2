require 'spec_helper'

include Conjur::DSL2

describe Plan do
  let(:plan) { Plan.new namespace }
  let(:namespace) { nil }
  context "in policy 'test'" do
    before {
      plan.policy = double(:policy, id: "test")
    }
    describe "#scoped_id" do
      context "in namespace 'my'" do
        let(:namespace) { "my" }
        describe "#scoped_id" do
          context "of nil" do
            specify {
              expect(plan.scoped_id nil).to eq("my/test")
            }
          end
        end
      end
      context "of nil" do
        specify {
          expect(plan.scoped_id nil).to eq("test")
        }
      end
    end
  end
  context "in namespace 'my'" do
    let(:namespace) { "my" }
    describe "#scoped_id" do
      context "of nil" do
        specify {
          expect(plan.scoped_id nil).to eq("my")
        }
      end
    end
  end
  
end
