# encoding: utf-8
require 'spec_helper'

describe Her::Model do
  before do
    spawn_model('Foo::User') { has_many :comments }
    spawn_model('Foo::Comment')

    stub_api_for(Foo::User) do |stub|
      stub.get("/users/1") { |env| [200, {}, { :id => 1, :name => "Tobias Fünke" }.to_json] }
    end

    stub_api_for(Foo::Comment) do |stub|
      stub.get("/users/1/comments") { |env| [200, {}, [{ :id => 4, :body => "They're having a FIRESALE?" }].to_json] }
    end
  end

  subject { Foo::User.find(1) }

  describe :has_key? do
    it { should_not have_key(:unknown_method_for_a_user) }
    it { should_not have_key(:unknown_method_for_a_user) }
    it { should have_key(:name) }
    it { should have_key(:comments) }
  end

  describe :[] do
    it { should_not have_key(:unknown_method_for_a_user) }
    specify { subject[:name].should == "Tobias Fünke" }
    specify { subject[:comments].first.body.should == "They're having a FIRESALE?" }
  end
end
