# frozen_string_literal: true

RSpec.describe Jsonapi::QueryBuilder::Mixins::Paginate do
  describe "DSL" do
    subject(:paginatable_query_class) do
      require "jsonapi/query_builder/paginator/kaminari"

      Class.new do
        include Jsonapi::QueryBuilder::Mixins::Paginate
      end
    end

    before do
      stub_const "PaginatableQuery", paginatable_query_class
    end

    describe ".paginator" do
      it "registers a new paginator" do
        PaginatableQuery.paginator Jsonapi::QueryBuilder::Paginator::Kaminari

        expect(PaginatableQuery._paginator).to eql Jsonapi::QueryBuilder::Paginator::Kaminari
      end
    end

    describe "._paginator" do
      it "defaults to Pagy paginator" do
        expect(PaginatableQuery._paginator).to eql Jsonapi::QueryBuilder::Paginator::Pagy
      end
    end
  end

  describe "#paginate" do
    subject(:paginate) { paged_query.paginate(collection) }

    let(:paged_query_class) do
      Class.new do
        include Jsonapi::QueryBuilder::Mixins::Paginate

        attr_reader :params

        def initialize(params)
          @params = params
        end
      end
    end
    let(:collection) { instance_double "collection" }
    let(:paged_query) { PagedQuery.new page: {number: 2, size: 20, offset: 0} }
    let(:paged_collection) { instance_double "paged-collection" }
    let(:pagination_details) { instance_double "pagination-details" }
    let(:paginator) do
      instance_double Jsonapi::QueryBuilder::Paginator::Pagy, paginate: [paged_collection, pagination_details]
    end

    before do
      stub_const "PagedQuery", paged_query_class
      allow(Jsonapi::QueryBuilder::Paginator::Pagy).to receive(:new).and_return(paginator)
    end

    it "returns the paged collection" do
      expect(paginate).to eql(paged_collection)
    end

    it "sets pagination details" do
      paginate

      expect(paged_query.pagination_details).to eql(pagination_details)
    end

    it "passes the collection and params to default Pagy paginator" do # rubocop:disable RSpec/MultipleExpectations
      paginate

      expect(Jsonapi::QueryBuilder::Paginator::Pagy).to have_received(:new).with(collection)
      expect(paginator).to have_received(:paginate).with(number: 2, size: 20, offset: 0)
    end

    it "defaults to page number 1" do
      paged_query.params[:page].delete(:number)

      paginate

      expect(paginator).to have_received(:paginate).with(hash_including(number: 1))
    end

    context "when paginate params are passed explicitly to #paginate" do
      subject(:paginate) { paged_query.paginate(collection, page_params) }

      let(:page_params) { {number: 3, size: 30} }

      it "overrides with the passed page params" do
        paginate

        expect(paginator).to have_received(:paginate).with(number: 3, size: 30)
      end
    end
  end
end
