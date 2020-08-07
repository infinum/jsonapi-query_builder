# frozen_string_literal: true

RSpec.describe Jsonapi::QueryBuilder::Mixins::Include do
  let(:author_query_class) do
    Class.new {
      include Jsonapi::QueryBuilder::Mixins::Include

      attr_reader :params

      def initialize(params)
        @params = params
      end
    }
  end

  before do
    stub_const "AuthorQuery", author_query_class
  end

  describe "#includes" do
    subject(:add_includes) { AuthorQuery.new(include_params).add_includes(collection) }

    let(:collection) { instance_double "collection" }
    let(:include_params) { {} }

    before do
      allow(collection).to receive(:includes).and_return(collection)
    end

    it "returns the collection" do
      expect(add_includes).to eql(collection)
    end

    context "when include params are empty" do
      let(:include_params) { {} }

      it "includes an empty array" do
        add_includes

        expect(collection).to have_received(:includes).with([])
      end
    end

    context "when include params are present and includable" do
      let(:include_params) { {include: "books,posts.tags,comments"} }

      it "splits includes params to an array of nested includes" do
        add_includes

        expect(collection).to have_received(:includes).with([:books, {posts: :tags}, :comments])
      end
    end
  end
end
