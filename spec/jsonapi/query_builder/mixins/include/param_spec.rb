# frozen_string_literal: true

RSpec.describe Jsonapi::QueryBuilder::Mixins::Include::Param do
  subject(:include_param) { described_class.new(parameter) }

  let(:parameter) { "books.author.address" }
  # { books: [{author: [:address]}]}

  it "strips param" do
    expect(described_class.new(" books ")).to have_attributes relationship: :books
  end

  it "parses child of a param" do
    child = include_param.children.first

    expect(child).to have_attributes relationship: :author, children: [an_instance_of(described_class)]
  end

  it "parses the children recursively" do
    child = include_param.children.first
    child_of_child = child.children.first

    expect(child_of_child).to have_attributes relationship: :address, children: []
  end

  it "adds relationship as a children to a parent" do
    existing_param = described_class.new("books.author")
    added_child = described_class.new("ratings.user")
    existing_param.children << added_child

    expect(existing_param.children).to include have_attributes(relationship: :author), added_child
  end

  describe "#merge_children" do
    subject(:merge_children) { existing_param.merge_children(other_param) }

    let(:existing_param) { described_class.new("books.author") }
    let(:other_param) { described_class.new("books.comments") }

    it { is_expected.to be existing_param }

    it 'merges children into existing param' do
      expect(merge_children).to have_attributes relationship: :books,
                                                children: [have_attributes(relationship: :author),
                                                           have_attributes(relationship: :comments)]
    end

    it 'deeply merges children into nested param' do
      merge_children.merge_children(described_class.new("books.comments.user"))

      expect(existing_param).to have_attributes relationship: :books,
                                                children: [
                                                  have_attributes(relationship: :author, children: []),
                                                  have_attributes(relationship: :comments,
                                                                  children: [have_attributes(relationship: :user)]),
                                                ]
    end
  end

  describe "#serialize" do
    it "returns the relationship key when there are no children" do
      param = described_class.new('books')

      expect(param.serialize).to be :books
    end

    it "returns an key - value pair when there is one child" do
      param = described_class.new('books.authors')

      expect(param.serialize).to eql(books: :authors)
    end

    it "returns a key - array of values when there are multiple children" do
      param = described_class.new('books.authors')
      param.children << described_class.new('ratings')

      expect(param.serialize).to eql(books: [:authors, :ratings])
    end

    it "serializes children recursively" do
      param = described_class.new('books.authors.address')
      param.children << described_class.new('ratings.user')

      expect(param.serialize).to eql(books: [{authors: :address, ratings: :user}])
    end
  end

  describe ".deserialize_params" do
    subject(:deserialized_params) {
      described_class.deserialize_params(
        "books,books.authors.address,books.authors.comments,books.reviews.user,comments"
      )
    }

    it { is_expected.to be_an Array }
    it { is_expected.to all be_an_instance_of described_class }
    it { is_expected.to have_attributes size: 2 }

    it "deeply merges same params together" do
      books_params = deserialized_params.find { |param| param.relationship == :books }

      expect(books_params.children).to include(
        have_attributes(relationship: :authors, children: [have_attributes(relationship: :address),
          have_attributes(relationship: :comments)]),
        have_attributes(relationship: :reviews, children: [have_attributes(relationship: :user)]),
      )
    end

    it "serializes the params" do
      expect(deserialized_params.map(&:serialize)).to eql [
        :comments,
        books: [{reviews: :user, authors: [:address, :comments]}]
      ]
    end
  end
end
