# frozen_string_literal: true

RSpec.describe Jsonapi::QueryBuilder::Paginator::Pagy do
  describe "#paginate" do
    subject(:paginate) { pagy_paginator.paginate(number: 2, size: 20, offset: 3) }

    let(:pagy_paginator) { described_class.new(collection) }
    let(:collection) { instance_double "collection" }
    let(:paged_collection) { instance_double "paged-collection" }
    let(:pagination_details) { instance_double Pagy, "pagination-details" }

    before do
      allow(pagy_paginator).to receive(:pagy).and_return([pagination_details, paged_collection])
    end

    it { is_expected.to be_an Array }

    it "returns the records and pagination details" do
      expect(paginate).to eql [paged_collection, pagination_details]
    end

    it "passes the collection and pagination params to pagy method" do
      paginate

      expect(pagy_paginator).to have_received(:pagy).with(collection, page: 2, items: 20, outset: 3)
    end

    it "sets the private params attribute reader used internally by pagy backend" do
      paginate

      expect(pagy_paginator.send(:params)).to eql page: {number: 2, size: 20, offset: 3}
    end
  end
end
