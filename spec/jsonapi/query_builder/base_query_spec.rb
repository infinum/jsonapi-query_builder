# frozen_string_literal: true

RSpec.describe Jsonapi::QueryBuilder::BaseQuery do
  let(:query) { described_class.new(collection, params) }
  let(:collection) { instance_double "collection" }

  before do
    allow(query).to receive(:add_includes).and_return(collection)
  end

  describe "#results" do
    subject(:results) { query.results }

    let(:filtered_collection) { instance_double "filtered_collection" }
    let(:paged_filtered_collection) { instance_double "paged_filtered_collection" }
    let(:params) {
      {
        sort: "last_name,first_name",
        include: "books",
        filter: {first_name: "John"},
        page: {number: 1, size: 20, offset: 0}
      }
    }

    before do
      allow(query).to receive(:sort).and_return(collection)
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

  describe "#find" do
    subject(:find) { query.find(1) }

    let(:params) { {id: 2, include: "books.tags"} }

    before do
      allow(query).to receive(:find_by!)
    end

    it "finds by id" do
      find

      expect(query).to have_received(:find_by!).with(id: 1)
    end

    it "aliases record to find with default parameters" do
      query.record

      expect(query).to have_received(:find_by!).with(id: 2)
    end
  end

  describe "#find_by!" do
    subject(:find_by!) { query.find_by!(id: 1) }

    let(:params) { {include: "books.tags"} }
    let(:record) { instance_double "record" }

    before do
      allow(collection).to receive(:find_by!).and_return(record)
    end

    it { is_expected.to eql record }

    it "adds includes to the collection" do
      find_by!

      expect(query).to have_received(:add_includes).with(collection)
    end

    it "finds a record" do
      find_by!

      expect(collection).to have_received(:find_by!).with(id: 1)
    end

    it "finds by multiple kwargs" do
      query.find_by!(id: 1, first_name: "John")

      expect(collection).to have_received(:find_by!).with(id: 1, first_name: "John")
    end
  end
end
