# frozen_string_literal: true

RSpec.describe Jsonapi::QueryBuilder::Mixins::Sort::Static do
  subject(:static_sort) { described_class.new(:description, sort) }

  let(:collection) { instance_double("collection") }

  let(:sort_param) { Jsonapi::QueryBuilder::Mixins::Sort::Param.new("-description") }

  before do
    allow(collection).to receive(:order).and_return(collection)
  end

  describe "#results" do
    context "when sort is not given" do
      let(:sort) { nil }

      it "defaults to ordering collection by attribute name" do
        static_sort.results(collection, sort_param)

        expect(collection).to have_received(:order).with(description: :desc)
      end
    end

    context "when sort is a Proc" do
      let(:sort) { ->(collection, direction) { collection.order(foobar: direction) } }

      it "calls the provided proc" do
        static_sort.results(collection, sort_param)

        expect(collection).to have_received(:order).with(foobar: :desc)
      end
    end

    context "when sort is a class" do
      let(:sort_class_instance) { instance_double("SortClass", results: collection) }
      let(:sort) { SortClass }

      before do
        class_double("SortClass", new: sort_class_instance).as_stubbed_const
      end

      it "uses the provided sort class" do
        static_sort.results(collection, sort_param)

        expect(SortClass).to have_received(:new).with(collection, :desc)
        expect(sort_class_instance).to have_received(:results)
      end
    end
  end
end
