# frozen_string_literal: true

require "active_record"

RSpec.describe Jsonapi::QueryBuilder do
  it "has a version number" do
    expect(Jsonapi::QueryBuilder::VERSION).not_to be nil
  end

  context "with controller usage" do
    subject(:query) { Query.new(collection, params) }

    let(:query_class) {
      Class.new(Jsonapi::QueryBuilder::BaseQuery) {
        default_sort :last_name
        sorts_by :first_name
        sorts_by :last_name

        filters_by :first_name
        filters_by :email, ->(collection, query) { collection.where("email ilike ?", "%#{query}%") }
        filters_by :type, TypeFilter, if: :correct_type?
      }
    }
    let(:type_filter_class) {
      Class.new(Jsonapi::QueryBuilder::BaseFilter) {
        def query
          super.camelize
        end

        def results
          collection.where(type: query)
        end

        def correct_type?
          %w[User Admin].include?(query)
        end
      }
    }

    let(:collection) { instance_double "collection" }

    let(:params) {
      {
        "sort" => "first_name,-last_name",
        "include" => "books.tags",
        "filter" => {"email" => "j", "type" => "user"},
        "page" => {"number" => 1, "size" => 20, "offset" => 0}
      }
    }

    before do
      stub_const "TypeFilter", type_filter_class
      stub_const "Query", query_class

      allow(collection).to receive(:order).and_return(collection)
      allow(collection).to receive(:includes).and_return(collection)
      allow(collection).to receive(:where).and_return(collection)
      allow(collection).to receive(:count).and_return(2)
      allow(collection).to receive(:offset).and_return(collection)
      allow(collection).to receive(:limit).and_return(collection)
    end

    it { is_expected.to have_attributes(results: collection, pagination_details: an_instance_of(Pagy)) }

    describe "#results" do
      subject(:results) { query.results }

      it { is_expected.to eql collection }

      it "includes included relationships" do
        results

        expect(collection).to have_received(:includes).with([{books: :tags}])
      end

      it "orders the collection", :aggregate_failures do
        results

        expect(collection).to have_received(:order).with(first_name: :asc)
        expect(collection).to have_received(:order).with(last_name: :desc)
      end

      it "adds unique sort attribute" do
        results

        expect(collection).to have_received(:order).with(id: :asc)
      end

      it "filters the collection by passed filter params", :aggregate_failures do
        results

        expect(collection).to have_received(:where).with("email ilike ?", "%j%")
        expect(collection).to have_received(:where).with(type: "User")
      end

      it "paginates the collection", :aggregate_failures do
        results

        expect(collection).to have_received(:count)
        expect(collection).to have_received(:offset).with(0)
        expect(collection).to have_received(:limit).with(2)
      end
    end

    describe "#find" do
      subject(:find) { query.find(1) }

      let(:record) { instance_double "record" }

      before do
        allow(collection).to receive(:find_by!).and_return(record)
      end

      it { is_expected.to eql record }

      it "includes included relationships" do
        find

        expect(collection).to have_received(:includes).with([{books: :tags}])
      end

      it "finds the record" do
        find

        expect(collection).to have_received(:find_by!).with(id: 1)
      end
    end
  end
end
