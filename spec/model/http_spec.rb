# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe Her::Model::HTTP do
  context "binding a model with an API" do
    it "binds a model to an instance of Her::API" do
      api = Her::API.new
      api.setup :url => "https://api.example.com"

      spawn_model "Foo::User"
      Foo::User.uses_api api
      Foo::User.her_api.should_not == nil
      Foo::User.her_api.base_uri.should == "https://api.example.com"
    end

    it "binds a model directly to Her::API" do
      Her::API.setup :url => "https://api.example.com"

      spawn_model "Foo::User"

      Foo::User.her_api.should_not == nil
      Foo::User.her_api.base_uri.should == "https://api.example.com"
    end

    it "binds two models to two different instances of Her::API" do
      api1 = Her::API.new
      api1.setup :url => "https://api1.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
      end

      spawn_model "Foo::User"
      Foo::User.uses_api api1
      Foo::User.her_api.base_uri.should == "https://api1.example.com"

      api2 = Her::API.new
      api2.setup :url => "https://api2.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
      end

      spawn_model "Foo::Comment"
      Foo::Comment.uses_api api2
      Foo::Comment.her_api.base_uri.should == "https://api2.example.com"
    end

    it "binds one model to Her::API and another one to an instance of Her::API" do
      Her::API.setup :url => "https://api1.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
      end

      spawn_model "Foo::User"

      Foo::User.her_api.base_uri.should == "https://api1.example.com"

      api = Her::API.new
      api.setup :url => "https://api2.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
      end

      spawn_model "Foo::Comment"
      Foo::Comment.uses_api api
      Foo::Comment.her_api.base_uri.should == "https://api2.example.com"
    end

    it "binds a a model to it's superclass' her_api" do
      api = Her::API.new
      api.setup :url => "http://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
      end

      spawn_model "Foo::Superclass" do
        uses_api api
      end

      Foo::Subclass = Class.new(Foo::Superclass)
      Foo::Subclass.her_api.should == Foo::Superclass.her_api
    end

    it "allows subclasses to change her_api without changing the parent class' her_api" do
      api1 = Her::API.new
      api1.setup :url => "http://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
      end

      spawn_model "Foo::Superclass" do
        uses_api api1
      end

      api2 = Her::API.new
      api2.setup :url => "http://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
      end

      Foo::Subclass = Class.new(Foo::Superclass) do
        uses_api api2
      end

      Foo::Subclass.her_api.should_not == Foo::Superclass.her_api
    end
  end

  context "making HTTP requests" do
    before do
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users") do |env|
            if env[:params]["page"] == "2"
              [200, {}, [{ :id => 2 }].to_json]
            else
              [200, {}, [{ :id => 1 }].to_json]
            end
          end
          stub.get("/users/popular") { |env| [200, {}, [{ :id => 1 }, { :id => 2 }].to_json] }
          stub.get("/users/1") { |env| [200, {}, { :id => 1 }.to_json] }
          stub.post("/users") { |env| [200, {}, [{ :id => 3 }].to_json] }
          stub.put("/users/4") { |env| [200, {}, [{ :id => 4 }].to_json] }
          stub.patch("/users/6") { |env| [200, {}, [{ :id => 6 }].to_json] }
          stub.delete("/users/5") { |env| [200, {}, [{ :id => 5 }].to_json] }
        end
      end

      spawn_model "Foo::User"
    end

    it "handles GET wrapper method" do
      @users = Foo::User.get(:popular)
      @users.length.should == 2
      @users.first.id.should == 1

      @user = Foo::User.get(:"1")
      @user.id.should == 1
    end

    it "handles raw GET with a block" do
      Foo::User.get_raw("/users") do |parsed_data|
        parsed_data[:data].should == [{ :id => 1 }]
      end
    end

    it "handles raw GET with return value" do
      parsed_data = Foo::User.get_raw("/users")
      parsed_data[:data].should == [{ :id => 1 }]
    end

    it "handles raw POST with a block" do
      Foo::User.post_raw("/users") do |parsed_data|
        parsed_data[:data].should == [{ :id => 3 }]
      end
    end

    it "handles raw POST with return value" do
      parsed_data = Foo::User.post_raw("/users")
      parsed_data[:data].should == [{ :id => 3 }]
    end

    it "handles raw PUT with a block" do
      Foo::User.put_raw("/users/4") do |parsed_data|
        parsed_data[:data].should == [{ :id => 4 }]
      end
    end

    it "handles raw PUT with return value" do
      parsed_data = Foo::User.put_raw("/users/4")
      parsed_data[:data].should == [{ :id => 4 }]
    end

    it "handles raw PATCH with a block" do
      Foo::User.patch_raw("/users/6") do |parsed_data|
        parsed_data[:data].should == [{ :id => 6 }]
      end
    end

    it "handles raw PATCH with return value" do
      parsed_data = Foo::User.patch_raw("/users/6")
      parsed_data[:data].should == [{ :id => 6 }]
    end

    it "handles raw DELETE with a block" do
      Foo::User.delete_raw("/users/5") do |parsed_data|
        parsed_data[:data].should == [{ :id => 5 }]
      end
    end

    it "handles raw DELETE with return value" do
      parsed_data = Foo::User.delete_raw("/users/5")
      parsed_data[:data].should == [{ :id => 5 }]
    end

    it "handles querystring parameters" do
      Foo::User.get_raw("/users", :page => 2) do |parsed_data|
        parsed_data[:data].should == [{ :id => 2 }]
      end
    end

    it "handles GET collection" do
      @users = Foo::User.get_collection("/users/popular")
      @users.length.should == 2
      @users.first.id.should == 1
    end

    it "handles GET resource" do
      @user = Foo::User.get_resource("/users/1")
      @user.id.should == 1
    end

    it "handles GET collection through a symbol" do
      @users = Foo::User.get_collection(:popular)
      @users.length.should == 2
      @users.first.id.should == 1
    end

    it "handles GET resource through a symbol" do
      @user = Foo::User.get_resource(:"1")
      @user.id.should == 1
    end

    it "handles raw GET through a symbol" do
      Foo::User.get_raw(:popular) do |parsed_data|
        parsed_data[:data].should == [{ :id => 1 }, { :id => 2 }]
      end
    end
  end

  context "setting custom requests" do
    before do
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/popular") { |env| [200, {}, [{ :id => 1 }, { :id => 2 }].to_json] }
          stub.post("/users/from_default") { |env| [200, {}, { :id => 4 }.to_json] }
        end
      end

      spawn_model "Foo::User"
      Foo::User.custom_get :popular, :foobar
      Foo::User.custom_post :from_default
    end

    it "handles custom methods" do
      Foo::User.respond_to?(:popular).should be_true
      Foo::User.respond_to?(:foobar).should be_true
      Foo::User.respond_to?(:from_default).should be_true
    end

    it "handles custom GET requests" do
      @users = Foo::User.popular
      @users.length.should == 2
      @users.first.id.should == 1
    end

    it "handles custom POST requests" do
      @user = Foo::User.from_default(:name => "Tobias Fünke")
      @user.id.should be_true
    end
  end
end
