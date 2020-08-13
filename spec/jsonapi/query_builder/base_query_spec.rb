# frozen_string_literal: true

RSpec.describe Jsonapi::QueryBuilder::BaseQuery do
  subject(:results) { query.results }

  let(:query) { described_class.new(collection, params) }
  let(:collection) { instance_double "collection" }
  let(:filtered_collection) { instance_double "filtered_collection" }
  let(:paged_filtered_collection) { instance_double "paged_filtered_collection" }
  let(:params) do
    {
      sort: "last_name,first_name",
      include: "books",
      filter: {first_name: "John"},
      page: {number: 1, size: 20, offset: 0}
    }
  end

  before do
    allow(query).to receive(:sort).and_return(collection)
    allow(query).to receive(:add_includes).and_return(collection)
    allow(query).to receive(:filter).and_return(filtered_collection)
    allow(query).to receive(:paginate).and_return(paged_filtered_collection)
  end

  it "returns the collection" do
    expect(results).to eql paged_filtered_collection
  end

  it "sorts the collection" do
    results

    expect(query).to have_received(:sort).with(collection)
  end

  it "adds includes to the collection" do
    results

    expect(query).to have_received(:add_includes).with(collection)
  end

  it "filters the collection" do
    results

    expect(query).to have_received(:filter).with(collection)
  end

  it "paginates the collection" do
    results

    expect(query).to have_received(:paginate).with(filtered_collection)
  end
end
