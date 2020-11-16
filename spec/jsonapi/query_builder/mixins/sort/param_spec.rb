# frozen_string_literal: true

RSpec.describe Jsonapi::QueryBuilder::Mixins::Sort::Param do
  subject(:sort_param) { described_class.new(parameter) }

  let(:parameter) { "-attribute_name" }

  it "deserializes the parameter into desc and attribute" do
    expect(sort_param).to have_attributes descending: "-", attribute: "attribute_name"
  end

  it "descending equals null if parameter has ascending direction" do
    expect(described_class.new("attribute_name").descending).to be_nil
  end

  it "strips param" do
    expect(described_class.new("   -attribute_name   ")).to have_attributes descending: "-", attribute: "attribute_name"
  end

  describe ".deserialize_params" do
    subject { described_class.deserialize_params("first_name,-last_name") }

    it { is_expected.to be_an Array }
    it { is_expected.to all be_an_instance_of described_class }
    it { is_expected.to include have_attributes descending: nil, attribute: "first_name" }
    it { is_expected.to include have_attributes descending: "-", attribute: "last_name" }
  end

  describe "#serialize" do
    subject { sort_param.serialize }

    it { is_expected.to be_a String }
    it { is_expected.to eql "-attribute_name" }
  end

  describe "#direction" do
    subject { sort_param.direction }

    context "when parameter starts with -" do
      let(:parameter) { "-attribute_name" }

      it { is_expected.to be :desc }
    end

    context "when parameter does not start with -" do
      let(:parameter) { "attribute_name" }

      it { is_expected.to be :asc }
    end
  end
end
