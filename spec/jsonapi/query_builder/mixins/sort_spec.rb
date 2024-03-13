# frozen_string_literal: true

RSpec.describe Jsonapi::QueryBuilder::Mixins::Sort do
  describe "DSL" do
    subject(:sortable_query_class) {
      Class.new {
        include Jsonapi::QueryBuilder::Mixins::Sort
      }
    }

    before do
      stub_const "SortableQuery", sortable_query_class
    end

    describe ".unique_sort_attribute" do
      it "defaults to id ascending if not set" do
        expect(SortableQuery._unique_sort_attributes).to eql [id: :asc]
      end

      it "sets the unique sort attribute" do
        SortableQuery.unique_sort_attribute :email

        expect(SortableQuery._unique_sort_attributes).to eql [:email]
      end

      it "sets compound unique sort attributes" do
        SortableQuery.unique_sort_attributes :created_at, id: :asc

        expect(SortableQuery._unique_sort_attributes).to eql [:created_at, id: :asc]
      end
    end

    describe ".default_sort" do
      it "sets the default sort setting" do
        SortableQuery.default_sort created_at: :desc

        expect(SortableQuery._default_sort).to eql created_at: :desc
      end

      it "sets the default sort to a proc" do
        SortableQuery.default_sort ->(collection) { collection.order(created_at: :desc) }

        expect(SortableQuery._default_sort).to be_an_instance_of(Proc)
      end

      it "sets the default sort to a sort class" do
        street_sort_class = class_double "StreetSort"
        SortableQuery.default_sort street_sort_class

        expect(SortableQuery._default_sort).to be street_sort_class
      end
    end

    describe ".sorts_by" do
      it "registers a supported sort attribute" do
        SortableQuery.sorts_by :first_name

        expect(SortableQuery.supported_sorts).to include(:first_name)
      end

      it "adds a default sort proc" do
        SortableQuery.sorts_by :first_name

        expect(SortableQuery.supported_sorts)
          .to include(first_name: an_instance_of(Jsonapi::QueryBuilder::Mixins::Sort::Static)
                                    .and(have_attributes(attribute: :first_name, sort: Proc)))
      end

      it "adds a custom sort" do
        sort = ->(collection, direction) { collection.order(first_name: direction) }

        SortableQuery.sorts_by :first_name, sort

        expect(SortableQuery.supported_sorts).to include(first_name: have_attributes(sort: sort))
      end

      it "can add multiple different sorts" do
        SortableQuery.sorts_by :first_name
        SortableQuery.sorts_by :last_name

        expect(SortableQuery.supported_sorts).to include(:first_name, :last_name)
      end
    end

    describe ".dynamically_sorts_by" do
      it "registers a supported dynamic sort attribute" do
        sort = Class.new(Jsonapi::QueryBuilder::DynamicSort)
        SortableQuery.dynamically_sorts_by :address, sort

        expect(SortableQuery.supported_dynamic_sorts)
          .to include(an_instance_of(Jsonapi::QueryBuilder::Mixins::Sort::Dynamic)
                        .and(have_attributes(attribute_prefix: "address", sort: sort)))
      end

      it "can add multiple different dynamic sorts" do
        sort = Class.new(Jsonapi::QueryBuilder::DynamicSort)
        SortableQuery.dynamically_sorts_by :address, sort
        SortableQuery.dynamically_sorts_by :email, sort

        expect(SortableQuery.supported_dynamic_sorts).to include(have_attributes(attribute_prefix: "address"),
          have_attributes(attribute_prefix: "email"))
      end
    end
  end

  describe "#sort" do
    subject(:sort) { SortableQuery.new(collection, params).sort(collection) }

    let(:sortable_query_class) {
      Class.new {
        include Jsonapi::QueryBuilder::Mixins::Sort

        attr_reader :params

        unique_sort_attribute id: :asc
        sorts_by :last_name
        sorts_by :first_name, ->(collection, direction) { collection.order(name: direction) }
        dynamically_sorts_by :'data.', DynamicSort
        sorts_by :'address.street', StreetSort

        def initialize(collection, params)
          @collection = collection
          @params = params
        end
      }
    }
    let(:street_sort_class) { class_double "StreetSort", new: street_sort_instance }
    let(:street_sort_instance) { instance_double "street_sort", results: collection }
    let(:dynamic_sort_class) { class_double "DynamicSort", new: dynamic_sort_instance }
    let(:dynamic_sort_instance) { instance_double "dynamic_sort", results: collection }
    let(:collection) { instance_double "collection" }
    let(:params) { {sort: "first_name,-last_name,address.street,data.foobar"} }

    before do
      stub_const "StreetSort", street_sort_class
      stub_const "DynamicSort", dynamic_sort_class
      stub_const "SortableQuery", sortable_query_class

      allow(collection).to receive(:order).and_return(collection)
    end

    it { is_expected.to eql collection }

    it "sorts by the present simple sort" do
      sort

      expect(collection).to have_received(:order).with(last_name: :desc)
    end

    it "sorts by the present lambda sort" do
      sort

      expect(collection).to have_received(:order).with(name: :asc)
    end

    it "sorts by present class sort", :aggregate_failures do
      sort

      expect(StreetSort).to have_received(:new).with(collection, :asc)
      expect(street_sort_instance).to have_received(:results)
    end

    it "sorts by present dynamic sort" do
      sort

      expect(DynamicSort).to have_received(:new).with(collection, "foobar", :asc)
      expect(dynamic_sort_instance).to have_received(:results)
    end

    it "adds the unique sort attribute" do
      sort

      expect(collection).to have_received(:order).with(id: :asc)
    end

    context "when sort params are empty and a default sort is not set" do
      let(:params) { {} }

      it "fallbacks to the unique sort attributes", :aggregate_failures do
        sort

        expect(collection).to have_received(:order).once
        expect(collection).to have_received(:order).with(id: :asc)
      end
    end

    context "when sort params are empty and a default sort is set" do
      let(:params) { {} }

      before do
        SortableQuery.default_sort :first_name
      end

      it "adds a default sort" do
        sort

        expect(collection).to have_received(:order).with(:first_name)
      end

      it "ensures a unique sort attribute" do
        sort

        expect(collection).to have_received(:order).with(id: :asc)
      end

      context "when default sort has a direction set" do
        before do
          SortableQuery.default_sort first_name: :desc
        end

        it "add the default sort with the direction" do
          sort

          expect(collection).to have_received(:order).with(first_name: :desc)
        end
      end

      context "when default sort is a proc" do
        before do
          SortableQuery.default_sort ->(collection) { collection.order(first_name: :desc) }
        end

        it "applies the sort proc" do
          sort

          expect(collection).to have_received(:order).with(first_name: :desc)
        end
      end

      context "when default sort is a sort object" do
        before do
          SortableQuery.default_sort StreetSort
        end

        it "sorts with the sort object", :aggregate_failures do
          sort

          expect(StreetSort).to have_received(:new).with(collection)
          expect(street_sort_instance).to have_received(:results)
        end
      end
    end

    context "when one or more of sort params is not permitted" do
      let(:params) { {sort: "first_name,-data.some_nested_prop,email,-birth_date"} }

      context "when query does not support nested parameters" do
        it "raises an unpermitted sort parameters error" do
          expect { sort }.to raise_error(
            Jsonapi::QueryBuilder::Errors::UnpermittedSortParameters,
            "email and birth_date are not permitted sort attributes"
          )
        end
      end
    end

    context "when sort params are passed explicitly to #sort" do
      subject(:sort) { SortableQuery.new(collection, params).sort(collection, sort_params) }

      let(:params) { {sort: "email"} }
      let(:sort_params) { "first_name,-last_name" }

      it "overrides with the passed sort string", :aggregate_failures do
        sort

        expect(collection).not_to have_received(:order).with(email: :asc)
        expect(collection).to have_received(:order).with(name: :asc)
        expect(collection).to have_received(:order).with(last_name: :desc)
      end
    end
  end
end
