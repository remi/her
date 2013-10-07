# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe "Her::Model and ActiveModel::Dirty" do
  context "checking dirty attributes" do
    before do
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { :id => 1, :fullname => "Lindsay Fünke" }.to_json] }
          stub.get("/users/2") { |env| [200, {}, { :id => 2, :fullname => "Maeby Fünke" }.to_json] }
          stub.put("/users/1") { |env| [200, {}, { :id => 1, :fullname => "Tobias Fünke" }.to_json] }
          stub.put("/users/2") { |env| [400, {}, { :errors => { :email => ["cannot be blank"] } }.to_json] }
          stub.post("/users") { |env| [200, {}, { :id => 1, :fullname => "Tobias Fünke" }.to_json] }
        end
      end

      spawn_model "Foo::User" do
        attributes :fullname, :email
      end
    end

    context "for existing resource" do
      context "with successful save" do
        it "tracks dirty attributes" do
          user = Foo::User.find(1)
          user.fullname = "Tobias Fünke"
          user.fullname_changed?.should be_true
          user.email_changed?.should be_false
          user.should be_changed
          user.save
          user.should_not be_changed
        end
      end

      context "with erroneous save" do
        it "tracks dirty attributes" do
          user = Foo::User.find(2)
          user.fullname = "Tobias Fünke"
          user.fullname_changed?.should be_true
          user.email_changed?.should be_false
          user.should be_changed
          user.save
          user.should be_changed
        end
      end
    end

    context "for new resource" do
      it "tracks dirty attributes" do
        user = Foo::User.new
        user.fullname = "Tobias Fünke"
        user.fullname_changed?.should be_true
        user.should be_changed
        user.save
        user.should_not be_changed
      end
    end
  end
end
