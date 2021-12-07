# frozen_string_literal: true

RSpec.describe Jsonapi::QueryBuilder::BaseSort do
  let(:sort_class) { Class.new(described_class) }

  before do
    stub_const "FakeSort", sort_class
  end

  it "defaults to ascending sort direction" do
    expect(FakeSort.new(instance_double("collection"))).to have_attributes(direction: :asc)
  end

  context "with required interface methods" do
    it "raises an error for results method" do
      expect { FakeSort.new(instance_double("collection"), :desc).results }.to raise_error(
        NotImplementedError, "FakeSort should implement #results"
      )
    end
  end
end
