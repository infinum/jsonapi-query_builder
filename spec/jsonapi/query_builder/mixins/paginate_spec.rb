# frozen_string_literal: true

RSpec.describe Jsonapi::QueryBuilder::Mixins::Paginate do
  let(:paged_query_class) do
    Class.new do
      include Jsonapi::QueryBuilder::Mixins::Paginate

      attr_reader :params

      def initialize(params)
        @params = params
      end
    end
  end

  let(:paginator) { instance_double("paginator", paginate: [paged_collection, pagination_details]) }

  let(:paged_query) { paged_query_class.new(params) }

  describe "#paginate" do
    subject(:paginate) { paged_query.paginate(collection) }

    let(:collection) { instance_double "collection" }
    let(:pagination_details) { instance_double "pagination-details" }
    let(:paged_collection) { instance_double "paged-collection" }
    let(:params) { {page: {number: 2, size: 20, offset: 0}} }

    before do
      paged_query.paginator = paginator
    end

    it "returns the paged collection" do
      expect(paginate).to eql(paged_collection)
    end

    it "sets pagination details" do
      paginate

      expect(paged_query.pagination_details).to eql(pagination_details)
    end

    it "passes the collection and params to paginator" do
      paginate

      expect(paginator).to have_received(:paginate).with(collection, params)
    end
  end
end
