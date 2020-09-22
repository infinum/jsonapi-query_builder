# frozen_string_literal: true

RSpec.describe Jsonapi::QueryBuilder::Mixins::Sort do
  subject(:test_query_class) {
    Class.new {
      include Jsonapi::QueryBuilder::Mixins::Sort
    }
  }

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

      it "registers a nested sort attribute as last item" do
        TestQuery.sorts_by user: %i[first_name last_name]
        TestQuery.sorts_by :email

        expect(TestQuery._sort_attributes[-1]).to eql(user: %i[first_name last_name])
      end
    end
  end

  describe "#sort" do
    subject(:sort) { TestQuery.new(collection, sort_params).sort(collection) }

    let(:test_query_class) {
      Class.new {
        include Jsonapi::QueryBuilder::Mixins::Sort

        attr_reader :params

        unique_sort_attribute id: :asc
        sorts_by :first_name, :last_name

        def initialize(collection, params)
          @collection = collection
          @params = params
        end
      }
    }
    let(:collection) { instance_double "collection", reorder: reordered_collection }
    let(:reordered_collection) { instance_double "reordered_collection", order: ordered_collection }
    let(:ordered_collection) { instance_double "ordered_collection" }

    let(:sort_params) { {} }

    before do
      allow(Arel).to receive(:sql).with("first_name")
        .and_return(instance_double(Arel::Nodes::SqlLiteral, asc: "first_name_asc", desc: "first_name_desc"))
      allow(Arel).to receive(:sql).with("last_name")
        .and_return(instance_double(Arel::Nodes::SqlLiteral, asc: "last_name_asc", desc: "last_name_desc"))
    end

    it "returns the sorted collection" do
      expect(sort).to eql(ordered_collection)
    end

    context "when sort params are empty and a default sort is not set" do
      it "clears the order" do
        sort

        expect(collection).to have_received(:reorder).with(nil)
      end

      it "fallbacks to the unique sort attributes" do
        sort

        expect(reordered_collection).to have_received(:order).with(id: :asc)
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

        expect(reordered_collection).to have_received(:order).with(id: :asc)
      end
    end

    context "when sort params are present and permitted" do
      let(:sort_params) { {sort: "first_name,-last_name"} }

      it "sets asc order direction for params not starting with -" do
        sort

        expect(collection).to have_received(:reorder).with(include("first_name_asc"))
      end

      it "sets desc order direction for params starting with -" do
        sort

        expect(collection).to have_received(:reorder).with(include("last_name_desc"))
      end

      it "strips params" do
        TestQuery.new(collection, sort: " -first_name ,  last_name ").sort(collection)

        expect(collection).to have_received(:reorder).with(%w[first_name_desc last_name_asc])
      end
    end

    context "when sort params are nested attributes" do
      let(:joined_collection) { instance_double "joined_collection", reorder: reordered_collection }
      let(:collection_class) { Class.new }
      let(:user_arel_table) { instance_double "arel_table" }

      let(:sort_params) { {sort: "user.last_name,-user.first_name"} }

      before do
        stub_const "User", collection_class

        allow(collection).to receive(:left_joins).and_return(joined_collection)
        allow(collection).to receive(:model_name).and_return(instance_double("model_name", name: "User"))
        allow(collection_class).to receive(:arel_table).and_return(user_arel_table)
        allow(user_arel_table).to receive("[]").with("first_name").and_return(
          instance_double("user_last_name_arel_column", asc: "first_name_asc", desc: "first_name_desc")
        )
        allow(user_arel_table).to receive("[]").with("last_name").and_return(
          instance_double("user_last_name_arel_column", asc: "last_name_asc", desc: "last_name_desc")
        )

        TestQuery.sorts_by user: %i[first_name last_name]
      end

      it "left joins the nested table" do
        sort

        expect(collection).to have_received(:left_joins).with(:user)
      end

      it "splits the params to a hash" do
        sort

        expect(joined_collection).to have_received(:reorder).with(%w[last_name_asc first_name_desc])
      end
    end

    context "when one or more of sort params is not permitted" do
      let(:sort_params) { {sort: "first_name,email,birth_date,user.email,-user.first_name"} }

      context "when query does not support nested parameters" do
        it "raises an unpermitted sort parameters error" do
          expect { sort }.to raise_error(
            Jsonapi::QueryBuilder::Mixins::Sort::UnpermittedSortParameters,
            "email, birth_date, user.email, and user.first_name are not permitted sort attributes"
          )
        end
      end

      context "when query supports nested parameters" do
        before do
          TestQuery.sorts_by user: %i[first_name]
        end

        it "raises an unpermitted sort parameters error" do
          expect { sort }.to raise_error(
            Jsonapi::QueryBuilder::Mixins::Sort::UnpermittedSortParameters,
            "email, birth_date, and user.email are not permitted sort attributes"
          )
        end
      end
    end

    context "when sort params are passed explicitly to #sort" do
      subject(:sort) { TestQuery.new(collection, params).sort(collection, sort_params) }

      let(:params) { {sort: "email"} }
      let(:sort_params) { "first_name,-last_name" }

      it "overrides with the passed sort string" do
        sort

        expect(collection).to have_received(:reorder).with(%w[first_name_asc last_name_desc])
      end
    end
  end
end
