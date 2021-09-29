# frozen_string_literal: true

RSpec.describe Jsonapi::QueryBuilder::Errors::UnpermittedSortParameters do
  context "when there is a single unpermitted sort parameter" do
    let(:unpermitted_parameters) { %w[first_name] }

    it "raises an exception with a single unpermitted parameter error message" do
      expect {
        raise described_class, unpermitted_parameters
      }.to raise_error(described_class, "first_name is not a permitted sort attribute")
    end
  end

  context "when there are multiple unpermitted sort parameters" do
    let(:unpermitted_parameters) { %w[first_name last_name email] }

    it "raises an exception with multiple unpermitted parameters error message" do
      expect {
        raise described_class, unpermitted_parameters
      }.to raise_error(described_class, "first_name, last_name, and email are not permitted sort attributes")
    end
  end
end
