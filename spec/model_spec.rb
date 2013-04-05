# encoding: utf-8
require 'spec_helper'

describe Her::Model do
  before do
    Her::API.setup :url => "https://api.example.com" do |connection|
      connection.use Her::Middleware::FirstLevelParseJSON
      connection.adapter :test do |stub|
        stub.get("/users/1") { |env| [200, {}, { :id => 1, :name => "Tobias Fünke" }.to_json] }
        stub.get("/users/1/comments") { |env| [200, {}, [{ :id => 4, :body => "They're having a FIRESALE?" }].to_json] }
      
        stub.get("/messages/1") { |env| [200, {}, { :message_id => 1, :body => "Message Body" }.to_json] }
      end
    end

    spawn_model("Foo::User") { has_many :comments }
    spawn_model("Foo::Comment")
    spawn_model("Foo::Message") { primary_key :message_id }
  end
  subject { Foo::User.find(1) }

  describe :has_key? do
    it { should_not have_key(:unknown_method_for_a_user) }
    it { should_not have_key(:unknown_method_for_a_user) }
    it { should have_key(:name) }
    it { should have_key(:comments) }
  end

  describe :primary_key do
    subject { Foo::Message.find(1) } # Load the model with primary_key :message_id
    it "proxies id to the primary key column" do
      subject.id.should == 1
    end
    it "returns the primary_key value from to_param" do
      subject.to_param.should == 1
    end
  end

  describe :[] do
    it { should_not have_key(:unknown_method_for_a_user) }
    specify { subject[:name].should == "Tobias Fünke" }
    specify { subject[:comments].first.body.should == "They're having a FIRESALE?" }
  end
end
