# frozen_string_literal: true

RSpec.describe Jsonapi::QueryBuilder::BaseQuery do
  subject(:results) { query.results }

  let(:query) { described_class.new(collection, params) }
  let(:collection) { instance_double "collection" }
  let(:params) do
    {
      sort: "last_name,first_name"
    }
  end

  before do
    allow(query).to receive(:sort).and_return(collection)
    allow(query).to receive(:add_includes).and_return(collection)
    allow(query).to receive(:paginate).and_return(collection)
  end

  it "returns the collection" do
    expect(results).to eql collection
  end

  it "sorts the collection" do
    results

    expect(query).to have_received(:sort).with(collection)
  end

  it "adds includes to the collection" do
    results

    expect(query).to have_received(:add_includes).with(collection)
  end

  it "paginates the collection" do
    results

    expect(query).to have_received(:paginate).with(collection)
  end
end
