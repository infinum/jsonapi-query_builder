# frozen_string_literal: true

RSpec.describe Jsonapi::QueryBuilder::Paginator::BasePaginator do
  before do
    stub_const "FakePaginator", paginator_class
  end

  context "with required interface methods" do
    let(:paginator_class) { Class.new described_class }

    it "raises an error for paginate method" do
      expect {
        FakePaginator.new(instance_double("collection")).paginate(instance_double("page_params"))
      }.to raise_error(NotImplementedError, "FakePaginator should implement #paginate")
    end
  end
end
