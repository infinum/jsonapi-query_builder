# frozen_string_literal: true

require "jsonapi/query_builder/paginator/kaminari"

RSpec.describe Jsonapi::QueryBuilder::Paginator::Kaminari do
  describe "#paginate" do
    subject(:paginate) { described_class.new(collection).paginate(number: 2, size: 20, offset: 3) }

    let(:collection) { instance_double "collection" }
    let(:paged_collection) do
      instance_double "paged-collection", current_page: 2,
                                          limit_value: 20,
                                          total_count: 35,
                                          total_pages: 2,
                                          next_page: nil,
                                          prev_page: 1
    end

    before do
      allow(collection).to receive(:page).and_return(collection)
      allow(collection).to receive(:per).and_return(collection)
      allow(collection).to receive(:padding).and_return(paged_collection)
    end

    it { is_expected.to be_an Array }

    it "returns the paged collection as first item of the returned array" do
      expect(paginate[0]).to eql paged_collection
    end

    it "returns the pagination details as the second item of the returned array" do
      expected_pagination_details = {number: 2, size: 20, offset: 3,
                                     total: 35, total_pages: 2,
                                     next_page: nil, prev_page: 1}

      expect(paginate[1]).to eql expected_pagination_details
    end

    it "calls the kaminari pagination methods on the passed collection", :aggregate_failures do
      paginate

      expect(collection).to have_received(:page).with(2)
      expect(collection).to have_received(:per).with(20)
      expect(collection).to have_received(:padding).with(3)
    end
  end
end
