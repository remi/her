# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe Her::Model::Serialization do
  context "serializing a resource" do
    before do
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.post("/users")     { |env| [200, {}, { :id => 1, :name => "Tobias Funke" }.to_json] }
          stub.get("/users/1")    { |env| [200, {}, { :id => 1, :name => "Tobias Funke" }.to_json] }
          stub.put("/users/1")    { |env| [200, {}, { :id => 1, :name => "Tobias Funke" }.to_json] }
          stub.delete("/users/1") { |env| [200, {}, { :id => 1, :name => "Tobias Funke" }.to_json] }
          stub.get("/projects/1/comments") { |env| [200, {}, [{ :id => 1, :body => "Hello!" }].to_json] }
        end
      end

      spawn_model "Foo::User" do
        define_method :email do
          # Return an email address using the Users first name
          "#{name.split.first.downcase}@test.com"
        end
      end
    end

    describe :to_json do
      it "returns a JSON string with all attributes" do
        @user = Foo::User.find(1)
        json_string = @user.to_json
        json_string.should == '{"name":"Tobias Funke","id":1}'
      end

      it "forwards options to #as_json" do
        @user = Foo::User.find(1)
        json_string = @user.to_json(only: "name")
        json_string.should == '{"name":"Tobias Funke"}'
      end
    end

    describe :as_json do
      it "returns a Hash with all attributes" do
        @user = Foo::User.find(1)
        hash = @user.as_json
        hash.length.should == 2
        hash.should have_key("id")
        hash['id'].should == 1
        hash.should have_key("name")
        hash['name'].should == "Tobias Funke"
      end

      [:only, "only"].each do |key|
        [:name, "name", [:name], ["name"]].each do |value|
          context "#{key.inspect} => #{value.inspect}" do
            it "only includes the given attributes" do
              @user = Foo::User.find(1)
              hash = @user.as_json(key => value)
              hash.length.should == 1
              hash.should have_key("name")
              hash['name'].should == "Tobias Funke"
            end
          end
        end
      end

      [:except, "except"].each do |key|
        [:name, "name", [:name], ["name"]].each do |value|
          context "#{key.inspect} => #{value.inspect}" do
            it "excludes the given attributes" do
              @user = Foo::User.find(1)
              hash = @user.as_json(key => value)
              hash.length.should == 1
              hash.should have_key("id")
              hash['id'].should == 1
            end
          end
        end
      end

      [:methods, "methods"].each do |key|
        [:email, "email", [:email], ["email"]].each do |value|
          context "#{key.inspect} => #{value.inspect}" do
            it "includes the value of the given methods" do
              @user = Foo::User.find(1)
              hash = @user.as_json(key => value)
              hash.should have_key("email")
              hash['email'].should == "tobias@test.com"
            end
          end
        end
      end
    end
  end
end
