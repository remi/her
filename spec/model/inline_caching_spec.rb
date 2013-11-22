# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe Her::Model::InlineCaching do
  context "with caching enabled and disabled" do
    before do
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users") { |env| [200, {}, [{ :id => 1, :name => "Tobias Funke" }].to_json] }
          stub.get("/projects") { |env| [200, {}, [{ :id => 1, :body => "Foo Project" }].to_json] }
        end
      end

      spawn_model "Foo::User"
      spawn_model "Foo::Project" do
        disable_inline_caching
      end
    end

    it "should have cached the response" do
      rel = Foo::User.all
      col = rel.to_a
      rel.instance_variable_get(:"@_fetch").should be_a_kind_of(Array)
    end

    it "should not have cached the response" do
      rel = Foo::Project.all
      col = rel.to_a
      rel.instance_variable_get(:"@_fetch").should be_nil
    end
  end

end