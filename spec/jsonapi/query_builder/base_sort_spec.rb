# frozen_string_literal: true

RSpec.describe Jsonapi::QueryBuilder::BaseSort do
  before do
    stub_const "FakeSort", sort_class
  end

  context "with required interface methods" do
    let(:sort_class) { Class.new(described_class) }

    it "raises an error for results method" do
      expect { FakeSort.new(instance_double("collection"), :desc).results }.to raise_error(
        NotImplementedError, "FakeSort should implement #results"
      )
    end
  end
end
