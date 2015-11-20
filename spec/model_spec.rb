# encoding: utf-8
require 'spec_helper'

describe Her::Model do
  before do
    Her::API.setup :url => "https://api.example.com" do |connection|
      connection.use Her::Middleware::FirstLevelParseJSON
      connection.adapter :test do |stub|
        stub.get("/users/1") { |env| [200, {}, { :id => 1, :name => "Tobias Fünke" }.to_json] }
        stub.get("/users/1/comments") { |env| [200, {}, [{ :id => 4, :body => "They're having a FIRESALE?" }].to_json] }
      end
    end

    spawn_model("Foo::User") { has_many :comments }
    spawn_model("Foo::Comment")
  end
  subject { Foo::User.find(1) }

  describe :has_key? do
    it { should_not have_key(:unknown_method_for_a_user) }
    it { should_not have_key(:unknown_method_for_a_user) }
    it { should have_key(:name) }
    it { should have_key(:comments) }
  end

  describe :serialization do
    it 'should be serialized without an error' do
      expect { Marshal.dump(subject.comments) }.not_to raise_error
    end

    it 'should correctly load serialized object' do
       serialized_comments = Marshal.load(Marshal.dump(subject.comments))
       subject.comments.size.should eq(serialized_comments.size)
       subject.comments.first.id.should eq(serialized_comments.first.id)
       subject.comments.first.body.should eq(serialized_comments.first.body)
    end
  end

  describe :[] do
    it { should_not have_key(:unknown_method_for_a_user) }
    specify { subject[:name].should == "Tobias Fünke" }
    specify { subject[:comments].first.body.should == "They're having a FIRESALE?" }
  end
end
