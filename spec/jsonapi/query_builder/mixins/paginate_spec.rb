# frozen_string_literal: true

RSpec.describe Jsonapi::QueryBuilder::Mixins::Paginate do
  let(:paged_query_class) do
    Class.new {
      include Jsonapi::QueryBuilder::Mixins::Paginate

      attr_reader :params

      def initialize(params)
        @params = params
      end
    }
  end
  let(:paged_query) { PagedQuery.new params }

  before do
    stub_const "PagedQuery", paged_query_class
  end

  describe "#paginate" do
    subject(:paginate) { paged_query.paginate(collection) }

    let(:collection) { instance_double "collection" }
    let(:pagination_details) { instance_double "pagination-details" }
    let(:paged_collection) { instance_double "paged-collection" }
    let(:params) { {page: {number: 2, size: 20, outset: 0}} }

    before do
      allow(paged_query).to receive(:pagy).and_return([pagination_details, paged_collection])
    end

    it "returns the paged collection" do
      expect(paginate).to eql(paged_collection)
    end

    it "sets pagination details" do
      paginate

      expect(paged_query.pagination_details).to eql(pagination_details)
    end

    it "defaults to page number 1" do
      params[:page].delete(:number)

      paginate

      expect(paged_query).to have_received(:pagy).with(anything, hash_including(page: 1))
    end

    context "when paginate params are passed explicitly to #paginate" do
      subject(:paginate) { paged_query.paginate(collection, page_params) }

      let(:page_params) { {number: 3, size: 30} }

      it "overrides with the passed page params" do
        paginate

        expect(paged_query).to have_received(:pagy).with(anything, hash_including(page: 3, items: 30))
      end
    end
  end
end
