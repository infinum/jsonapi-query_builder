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
  let(:paged_query) { PagedQuery.new page_params }

  before do
    stub_const "PagedQuery", paged_query_class
  end

  describe "#paginate" do
    subject(:paginate) { paged_query.paginate(collection) }

    let(:collection) { instance_double "collection" }
    let(:pagination_details) { instance_double "pagination-details" }
    let(:paged_collection) { instance_double "paged-collection" }
    let(:page_params) { {} }

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
  end
end
