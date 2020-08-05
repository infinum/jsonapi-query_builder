# frozen_string_literal: true

RSpec.describe Jsonapi::QueryBuilder::Mixins::Sort do
  subject(:test_query_class) do
    Class.new {
      include Jsonapi::QueryBuilder::Mixins::Sort
    }
  end

  before do
    stub_const "TestQuery", test_query_class
  end

  describe "DSL" do
    describe ".unique_sort_attribute" do
      it "defaults to id ascending if not set" do
        expect(TestQuery._unique_sort_attributes).to eql [id: :asc]
      end

      it "sets the unique sort attribute" do
        TestQuery.unique_sort_attribute :email

        expect(TestQuery._unique_sort_attributes).to eql [:email]
      end

      it "sets compound unique sort attributes" do
        TestQuery.unique_sort_attributes :created_at, id: :asc

        expect(TestQuery._unique_sort_attributes).to eql [:created_at, id: :asc]
      end
    end

    describe ".default_sort" do
      it "sets the default sort setting" do
        TestQuery.default_sort created_at: :desc

        expect(TestQuery._default_sort).to eql created_at: :desc
      end
    end

    describe ".sorts_by" do
      it "registers a supported sort attribute" do
        TestQuery.sorts_by :first_name

        expect(TestQuery._sort_attributes).to include(:first_name)
      end

      it "registers multiple sort attributes at the same time" do
        TestQuery.sorts_by :first_name, :last_name

        expect(TestQuery._sort_attributes).to include(:first_name, :last_name)
      end

      it "does not clear existing registered sort attributes" do
        TestQuery.sorts_by :first_name
        TestQuery.sorts_by :last_name

        expect(TestQuery._sort_attributes).to include(:first_name, :last_name)
      end
    end
  end

  describe "#sort" do
    subject(:sort) { TestQuery.new(sort_params).sort(collection) }

    let(:test_query_class) do
      Class.new {
        include Jsonapi::QueryBuilder::Mixins::Sort

        attr_reader :params

        unique_sort_attribute id: :asc
        sorts_by :first_name, :last_name

        def initialize(params)
          @params = params
        end
      }
    end
    let(:collection) { instance_double "collection" }
    let(:sort_params) { {} }

    before do
      allow(collection).to receive(:reorder).and_return(collection)
      allow(collection).to receive(:order).and_return(collection)
    end

    it "returns the sorted collection" do
      expect(sort).to eql(collection)
    end

    context "when sort params are empty and a default sort is not set" do
      it "clears the order" do
        sort

        expect(collection).to have_received(:reorder).with(nil)
      end

      it "fallbacks to the unique sort attributes" do
        sort

        expect(collection).to have_received(:order).with(id: :asc)
      end
    end

    context "when sort params are empty and a default sort is set" do
      before do
        TestQuery.default_sort :first_name
      end

      it "adds a default sort" do
        sort

        expect(collection).to have_received(:reorder).with(:first_name)
      end

      it "ensures a unique sort attribute" do
        sort

        expect(collection).to have_received(:order).with(id: :asc)
      end
    end

    context "when sort params are present and permitted" do
      let(:sort_params) { {sort: "first_name,-last_name"} }

      it "splits the params to a hash" do
        sort

        expect(collection).to have_received(:reorder).with(first_name: anything, last_name: anything)
      end

      it "sets asc order direction for params not starting with -" do
        sort

        expect(collection).to have_received(:reorder).with(hash_including(first_name: :asc))
      end

      it "sets desc order direction for params starting with -" do
        sort

        expect(collection).to have_received(:reorder).with(hash_including(last_name: :desc))
      end

      it "strips params" do
        TestQuery.new(sort: " first_name ,  -last_name ").sort(collection)

        expect(collection).to have_received(:reorder).with(first_name: anything, last_name: anything)
      end
    end

    context "when one or more of sort params is not permitted" do
      let(:sort_params) { {sort: "first_name,email,birth_date"} }

      it "raises an unpermitted sort parameters error" do
        expect { sort }.to raise_error(
          Jsonapi::QueryBuilder::Mixins::Sort::UnpermittedSortParameters,
          "email and birth_date are not permitted sort attributes"
        )
      end
    end

    context "when sort params are passed explicitly to #sort" do
      subject(:sort) { TestQuery.new(params).sort(collection, sort_params) }

      let(:params) { {sort: "email"} }
      let(:sort_params) { "first_name,-last_name" }

      it "overrides with the passed sort string" do
        sort

        expect(collection).to have_received(:reorder).with(first_name: :asc, last_name: :desc)
      end
    end
  end
end
