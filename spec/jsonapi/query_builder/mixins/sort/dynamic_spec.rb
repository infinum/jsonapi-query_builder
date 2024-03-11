# frozen_string_literal: true

RSpec.describe Jsonapi::QueryBuilder::Mixins::Sort::Dynamic do
  subject(:dynamic_sort) { described_class.new(:'data.', sort) }

  let(:collection) { instance_double("collection") }
  let(:sort) { ->(collection, attribute, direction) { collection.order(attribute => direction) } }
  let(:sort_param) { Jsonapi::QueryBuilder::Mixins::Sort::Param.new("-data.description") }

  before do
    allow(collection).to receive(:order).and_return(collection)
  end

  describe "#matches?" do
    context "when sort attribute starts with configured prefix" do
      it "returns true" do
        expect(dynamic_sort.matches?(:'data.description')).to be true
      end
    end

    context "when sort attribute does not match" do
      it "returns false" do
        expect(dynamic_sort.matches?(:description)).to be false
      end
    end
  end

  describe "#results" do
    context "when sort is a Proc" do
      it "calls the provided proc" do
        dynamic_sort.results(collection, sort_param)

        expect(collection).to have_received(:order).with('description' => :desc)
      end
    end

    context "when sort is a class" do
      let(:sort_class_instance) { instance_double("SortClass", results: collection) }
      let(:sort) { SortClass }

      before do
        class_double("SortClass", new: sort_class_instance).as_stubbed_const
      end

      it "uses the provided sort class" do
        dynamic_sort.results(collection, sort_param)

        expect(SortClass).to have_received(:new).with(collection, 'description', :desc)
        expect(sort_class_instance).to have_received(:results)
      end
    end
  end
end
