# frozen_string_literal: true

RSpec.describe Jsonapi::QueryBuilder::BaseFilter do
  before do
    stub_const "FakeFilter", filter_class
  end

  context "with required interface methods" do
    let(:filter_class) { Class.new(described_class) }

    it "raises an error for results method" do
      expect { FakeFilter.new(instance_double("collection"), "query").results }.to raise_error(
        NotImplementedError, "FakeFilter should implement #results"
      )
    end
  end
end
