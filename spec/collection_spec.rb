require "spec_helper"

describe Her::Collection do
  let(:items) { [1, 2, 3, 4] }
  let(:metadata) { { name: "Testname" } }
  let(:errors) { { name: ["not_present"] } }

  describe "#new" do
    context "without parameters" do
      subject { Her::Collection.new }

      it { is_expected.to eq([]) }

      describe "#metadata" do
        subject { super().metadata }
        it { is_expected.to eq({}) }
      end

      describe "#errors" do
        subject { super().errors }
        it { is_expected.to eq({}) }
      end
    end

    context "with parameters" do
      subject { Her::Collection.new(items, metadata, errors) }

      it { is_expected.to eq([1, 2, 3, 4]) }

      describe "#metadata" do
        subject { super().metadata }
        it { is_expected.to eq(name: "Testname") }
      end

      describe "#errors" do
        subject { super().errors }
        it { is_expected.to eq(name: ["not_present"]) }
      end
    end
  end
end
