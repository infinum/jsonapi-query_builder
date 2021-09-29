# frozen_string_literal: true

RSpec.describe Jsonapi::QueryBuilder::Mixins::Filter do
  describe "DSL" do
    subject(:filterable_query_class) do
      Class.new do
        include Jsonapi::QueryBuilder::Mixins::Filter
      end
    end

    before do
      stub_const "FilterableQuery", filterable_query_class
    end

    describe ".filters_by" do
      it "registers a new filter for an attribute" do
        FilterableQuery.filters_by :first_name

        expect(FilterableQuery.supported_filters).to include(:first_name)
      end

      it "adds a default filter proc" do
        FilterableQuery.filters_by :first_name

        expect(FilterableQuery.supported_filters).to include(first_name: include(an_instance_of(Proc)))
      end

      it "adds a custom filter" do
        filter = ->(collection, query) { collection.where(first_name: query) }

        FilterableQuery.filters_by :first_name, filter

        expect(FilterableQuery.supported_filters).to include(first_name: include(filter))
      end

      it "saves filter options" do
        FilterableQuery.filters_by :first_name, query_parameter: "name"

        expect(FilterableQuery.supported_filters).to include(first_name: include(query_parameter: "name"))
      end

      it "can add multiple different filters" do
        FilterableQuery.filters_by :first_name, query_parameter: "name"
        FilterableQuery.filters_by :last_name, query_parameter: "surname"

        expect(FilterableQuery.supported_filters).to include(first_name: include(query_parameter: "name"),
                                                             last_name: include(query_parameter: "surname"))
      end
    end
  end

  describe "#filter" do
    subject(:filter) { FilterableQuery.new(params).filter(collection) }

    let(:filterable_query_class) do
      Class.new {
        include Jsonapi::QueryBuilder::Mixins::Filter

        attr_reader :params

        filters_by :first_name
        filters_by :email, ->(collection, query) { collection.where("email ilike ?", "%#{query}%") }
        filters_by :type, TypeFilter

        def initialize(params)
          @params = params
        end
      }
    end
    let(:type_filter_class) { class_double "TypeFilter", new: type_filter_instance }
    let(:type_filter_instance) { instance_double "type_filter", results: collection }
    let(:collection) { instance_double "collection" }
    let(:params) { {filter: {first_name: "John", email: "john", type: "user"}} }

    before do
      stub_const "TypeFilter", type_filter_class
      stub_const "FilterableQuery", filterable_query_class

      allow(collection).to receive(:where).and_return(collection)
    end

    it { is_expected.to eql collection }

    it "filters by present simple filter" do
      filter

      expect(collection).to have_received(:where).with(first_name: "John")
    end

    it "filters by present lambda filter" do
      filter

      expect(collection).to have_received(:where).with("email ilike ?", "%john%")
    end

    it "filters by present class filter", :aggregate_failures do
      filter

      expect(TypeFilter).to have_received(:new).with(collection, "user")
      expect(type_filter_instance).to have_received(:results)
    end

    it "does not filter if parameters are omitted", :aggregate_failures do
      params[:filter].delete(:first_name)

      filter

      expect(collection).to have_received(:where)
      expect(collection).not_to have_received(:where).with(first_name: anything)
    end

    context "with additional options" do
      it "overrides the filter query parameter name" do
        FilterableQuery.filters_by :first_name, query_parameter: "name"
        params[:filter][:name] = params[:filter].delete(:first_name)

        filter

        expect(collection).to have_received(:where).with(first_name: "John")
      end

      context "with allow nil" do
        before do
          FilterableQuery.filters_by :first_name, allow_nil: true
        end

        it "allows blank values for explicit checks against null" do
          params[:filter][:first_name] = ""

          filter

          expect(collection).to have_received(:where).with(first_name: nil)
        end

        it "does not check against null if parameter is not present" do
          params[:filter].delete(:first_name)

          filter

          expect(collection).not_to have_received(:where).with(first_name: nil)
        end
      end

      context "with custom conditions" do
        let(:params) { {filter: {first_name: "J", last_name: "Wi"}} }

        it "adds custom if condition", :aggregate_failures do
          FilterableQuery.filters_by :first_name, if: ->(query) { query.length >= 2 }
          FilterableQuery.filters_by :last_name, if: ->(query) { query.length >= 2 }

          filter

          expect(collection).not_to have_received(:where).with(first_name: anything)
          expect(collection).to have_received(:where).with(last_name: "Wi")
        end

        it "adds custom unless condition", :aggregate_failures do
          FilterableQuery.filters_by :first_name, unless: ->(query) { query.length < 2 }
          FilterableQuery.filters_by :last_name, unless: ->(query) { query.length < 2 }

          filter

          expect(collection).not_to have_received(:where).with(first_name: anything)
          expect(collection).to have_received(:where).with(last_name: "Wi")
        end

        it "check the predicate method of a filter passed by a symbol", :aggregate_failures do
          FilterableQuery.filters_by :type, TypeFilter, if: :correct_type?
          allow(type_filter_instance).to receive(:correct_type?).and_return(true)

          filter

          expect(type_filter_instance).to have_received(:correct_type?)
          expect(type_filter_instance).to have_received(:results)
        end

        it "does not filter if predicate method is false" do
          FilterableQuery.filters_by :type, TypeFilter, if: :correct_type?
          allow(type_filter_instance).to receive(:correct_type?).and_return(false)

          filter

          expect(type_filter_instance).not_to have_received(:results)
        end
      end
    end

    context "when no filters are set" do
      let(:filterable_query_class) do
        Class.new {
          include Jsonapi::QueryBuilder::Mixins::Filter

          attr_reader :params

          def initialize(params)
            @params = params
          end
        }
      end

      it "returns the collection" do
        expect(filter).to eql collection
      end
    end
  end
end
