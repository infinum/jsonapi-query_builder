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
    let(:include_params) { {include: "books,address"} }

    before do
      allow(collection).to receive(:includes).and_return(collection)
    end

    it "returns the collection" do
      expect(add_includes).to eql(collection)
    end

    it "includes parsed include params" do
      add_includes

      expect(collection).to have_received(:includes).with(:books, :address)
    end

    context "when include params are empty" do
      let(:include_params) { {} }

      it "does not include anything when include params are empty" do
        add_includes

        expect(collection).not_to have_received(:includes)
      end
    end

    context "with nested includes" do
      subject(:author_query) { AuthorQuery.new({}) }

      it "adds nested includes as a single hash" do
        author_query.add_includes(collection, "books,books.tags,books.comments")

        expect(collection).to have_received(:includes).with(an_instance_of(Hash))
      end

      it "adds nested relationships next to top level relationships" do
        author_query.add_includes(collection, "address,books.tags")

        expect(collection).to have_received(:includes).with(:address, books: :tags)
      end

      it "does not include relationships that have nested includes" do
        author_query.add_includes(collection, "books,books.tags,books.comments")

        expect(collection).not_to have_received(:includes).with(array_including(:books))
      end

      it "includes single nested includes as parent - nested relationship" do
        author_query.add_includes(collection, "books.tags")

        expect(collection).to have_received(:includes).with(books: :tags)
      end

      it "includes multiple nested includes as parent - nested relationships array" do
        author_query.add_includes(collection, "books.tags,books.comments")

        expect(collection).to have_received(:includes).with(books: [:tags, :comments])
      end

      it "includes all depths of relationships" do
        author_query.add_includes(collection, "books.tags,books.comments.user")

        expect(collection).to have_received(:includes).with(books: [:tags, { comments: :user }])
      end
    end
  end
end
