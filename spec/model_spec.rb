# encoding: utf-8
require 'spec_helper'

describe Her::Model do
  before do
    Her::API.setup :url => "https://api.example.com" do |builder|
      builder.use Her::Middleware::FirstLevelParseJSON
      builder.use Faraday::Request::UrlEncoded
      builder.adapter :test do |stub|
        stub.get("/users/1") { |env| [200, {}, { :id => 1, :name => "Tobias Fünke" }.to_json] }
        stub.get("/users/1/comments") { |env| [200, {}, [{ :id => 4, :body => "They're having a FIRESALE?" }].to_json] }
      end
    end

    spawn_model "Foo::User" do
      has_many :comments
    end

    spawn_model "Foo::Comment"

    @user_without_included_data = Foo::User.find(1)
  end

  it "handles has_key? for data" do
    @user_without_included_data.should_not have_key(:unknown_method_for_a_user)
    @user_without_included_data.should have_key(:name)
  end

  it "handles has_key? for relationships" do
    @user_without_included_data.should_not have_key(:unknown_method_for_a_user)
    @user_without_included_data.should have_key(:comments)
  end

  it "handles [] for data" do
    @user_without_included_data[:unknown_method_for_a_user].should be_nil
    @user_without_included_data[:name].should == "Tobias Fünke"
  end

  it "handles [] for relationships" do
    @user_without_included_data[:unknown_relationship].should be_nil
    @user_without_included_data[:comments].first.body.should == "They're having a FIRESALE?"
  end
end
