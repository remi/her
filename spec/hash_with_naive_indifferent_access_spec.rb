require "spec_helper"
require "byebug"

describe HashWithNaiveIndifferentAccess do
  subject { HashWithNaiveIndifferentAccess.new.tap { |h| h[:key] = 'value' } }

  describe "#[:key], #[:key]=" do
    subject { super()[:key] }
    it { is_expected.to eq('value') }
  end

  describe "#merge" do
    subject { super().merge(:new_key => 'new value')['new_key'] }
    it { is_expected.to eq('new value') }
  end

  describe "#merge!" do
    subject { super().merge!(:new_key => 'new value')['new_key'] }
    it { is_expected.to eq('new value') }
  end

  describe "#include?" do
    subject { super().include?(:key) }
    it { is_expected.to eq(true) }
  end
end
