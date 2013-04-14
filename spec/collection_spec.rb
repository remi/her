require 'spec_helper'

describe Her::Collection do
  before do
    spawn_model "Foo::User"
  end

  let(:items) { [1, 2, 3, 4] }
  let(:metadata) { { :name => 'Testname' } }
  let(:errors) { { :name => ['not_present'] } }
  let(:klass) { Foo::User }

  describe "#new" do
    context "without parameters" do
      subject { Her::Collection.new }

      it { should eq([]) }
      its(:metadata) { should eq({}) }
      its(:errors) { should eq({}) }
    end

    context "with parameters" do
      subject { Her::Collection.new(items, metadata, errors, klass) }

      it { should eq([1,2,3,4]) }
      its(:metadata) { should eq({ :name => 'Testname' }) }
      its(:errors) { should eq({ :name => ['not_present'] }) }
      its(:klass) { should eq(klass) }
    end
  end

  describe "#build" do
    let(:collection) { Her::Collection.new(items, metadata, errors, klass) }
    let(:build_params) { { :name => "Mr. Manager" } }

    context "without parameters" do
      subject { collection.build }

      it { should be_an_instance_of(klass) }
    end

    context "with parameters" do
      subject { collection.build(build_params) }

      it { should be_an_instance_of(klass) }
      its(:name) { should eq(build_params[:name]) }
    end
  end
end
