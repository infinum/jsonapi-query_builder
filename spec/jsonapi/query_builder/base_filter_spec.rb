# frozen_string_literal: true

RSpec.describe Jsonapi::QueryBuilder::BaseFilter do
  before do
    stub_const 'FakeFilter', filter_class
  end

  context 'with required interface methods' do
    let(:filter_class) { Class.new(described_class) }

      expect { FakeFilter.new(instance_double("collection"), "query").results }.to raise_error(
        NotImplementedError, "FakeFilter should implement #results"
    it 'raises an error for results method' do
      )
    end
  end
end
