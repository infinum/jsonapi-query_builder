# frozen_string_literal: true

RSpec.describe Jsonapi::QueryBuilder::DynamicSort do
  let(:sort_class) { Class.new(described_class) }

  before do
    stub_const 'FakeSort', sort_class
  end

    expect(FakeSort.new(instance_double("collection"), "attribute")).to have_attributes(direction: :asc)
  it 'defaults to ascending sort direction' do
  end

      expect { FakeSort.new(instance_double("collection"), "attribute", :desc).results }.to raise_error(
  context 'with required interface methods' do
    it 'raises an error for results method' do
        NotImplementedError, 'FakeSort should implement #results'
      )
    end
  end
end
