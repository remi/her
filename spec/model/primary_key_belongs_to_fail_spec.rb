# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe "primary_key belongs_to fail", :focus => true do

  context "without primary_key set" do
    before do
      Her::API.setup :url => "https://api.example.com/api" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.adapter :test do |stub|
          stub.get('/api/actors/x1') { [200, {}, MultiJson.encode({
            "uid"           => "x1",
            "organization"  => {"name" => "TestOrg"},
            "user"          => {"email" => "x1@localhost"}
          })]}
        end
      end

      spawn_model "Foo::Actor" do
        belongs_to :user
      end

      spawn_model "Foo::User" do

      end
    end

    it "works" do
      Foo::Actor.find("x1").user.email.should == "x1@localhost"
    end
  end

  context "with primary_key set" do
    before do
      Her::API.setup :url => "https://api.example.com/api" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.adapter :test do |stub|
          stub.get('/api/actors/x1') { [200, {}, MultiJson.encode({
            "uid"           => "x1",
            "organization"  => {"name" => "TestOrg"},
            "user"          => {"email" => "x1@localhost"}
          })]}
        end
      end

      spawn_model "Foo::Actor" do
        primary_key :uid
        belongs_to :user
      end

      spawn_model "Foo::User" do

      end
    end

    it "works" do
      Foo::Actor.find("x1").user.email.should == "x1@localhost"
    end
  end
end
