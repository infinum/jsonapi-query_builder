# frozen_string_literal: true

RSpec.describe Jsonapi::QueryBuilder::BaseQuery do
  let(:query) { described_class.new(collection, params) }
  let(:collection) { instance_double "collection" }
  let(:params) { {} }

  describe "#results" do
    subject(:results) { collection.results }

    it "returns the collection" do
      expect(query.results).to eql collection
    end
  end
end
