# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe Her::Model::HTTP do
  context "binding a model with an API" do
    it "binds a model to an instance of Her::API" do # {{{
      api = Her::API.new
      api.setup :base_uri => "https://api.example.com"

      spawn_model :User do
        uses_api api
        @her_api.should_not == nil
        @her_api.base_uri.should == "https://api.example.com"
      end
    end # }}}

    it "binds a model directly to Her::API" do # {{{
      Her::API.setup :base_uri => "https://api.example.com"

      spawn_model :User do
        @her_api.should_not == nil
        @her_api.base_uri.should == "https://api.example.com"
      end
    end # }}}

    it "binds two models to two different instances of Her::API" do # {{{
      api1 = Her::API.new
      api1.setup :base_uri => "https://api1.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
      end

      spawn_model :User do
        uses_api api1
        @her_api.base_uri.should == "https://api1.example.com"
      end

      api2 = Her::API.new
      api2.setup :base_uri => "https://api2.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
      end

      spawn_model :Comment do
        uses_api api2
        @her_api.base_uri.should == "https://api2.example.com"
      end
    end # }}}

    it "binds one model to Her::API and another one to an instance of Her::API" do # {{{
      Her::API.setup :base_uri => "https://api1.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
      end

      spawn_model :User do
        @her_api.base_uri.should == "https://api1.example.com"
      end

      api = Her::API.new
      api.setup :base_uri => "https://api2.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
      end

      spawn_model :Comment do
        uses_api api
        @her_api.base_uri.should == "https://api2.example.com"
      end
    end # }}}
  end

  context "making HTTP requests" do
    before do # {{{
      Her::API.setup :base_uri => "https://api.example.com" do |builder|
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

      spawn_model :User
    end # }}}

    it "handle GET wrapper method" do # {{{
      @users = User.get(:popular)
      @users.length.should == 2
      @users.first.id.should == 1

      @user = User.get(:"1")
      @user.id.should == 1
    end # }}}

    it "handle raw GET" do # {{{
      User.get_raw("/users") do |parsed_data|
        parsed_data[:data].should == [{ :id => 1 }]
      end
    end # }}}

    it "handle raw POST" do # {{{
      User.post_raw("/users") do |parsed_data|
        parsed_data[:data].should == [{ :id => 3 }]
      end
    end # }}}

    it "handle raw PUT" do # {{{
      User.put_raw("/users/4") do |parsed_data|
        parsed_data[:data].should == [{ :id => 4 }]
      end
    end # }}}

    it "handle raw PATCH" do # {{{
      User.patch_raw("/users/6") do |parsed_data|
        parsed_data[:data].should == [{ :id => 6 }]
      end
    end # }}}

    it "handle raw DELETE" do # {{{
      User.delete_raw("/users/5") do |parsed_data|
        parsed_data[:data].should == [{ :id => 5 }]
      end
    end # }}}

    it "handle querystring parameters" do # {{{
      User.get_raw("/users", :page => 2) do |parsed_data|
        parsed_data[:data].should == [{ :id => 2 }]
      end
    end # }}}

    it "handle GET collection" do # {{{
      @users = User.get_collection("/users/popular")
      @users.length.should == 2
      @users.first.id.should == 1
    end # }}}

    it "handle GET resource" do # {{{
      @user = User.get_resource("/users/1")
      @user.id.should == 1
    end # }}}

    it "handle GET collection through a symbol" do # {{{
      @users = User.get_collection(:popular)
      @users.length.should == 2
      @users.first.id.should == 1
    end # }}}

    it "handle GET resource through a symbol" do # {{{
      @user = User.get_resource(:"1")
      @user.id.should == 1
    end # }}}

    it "handle raw GET through a symbol" do # {{{
      User.get_raw(:popular) do |parsed_data|
        parsed_data[:data].should == [{ :id => 1 }, { :id => 2 }]
      end
    end # }}}
  end

  context "setting custom requests" do
    before do # {{{
      Her::API.setup :base_uri => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/popular") { |env| [200, {}, [{ :id => 1 }, { :id => 2 }].to_json] }
          stub.post("/users/from_default") { |env| [200, {}, { :id => 4 }.to_json] }
        end
      end

      spawn_model :User do
        custom_get :popular, :foobar
        custom_post :from_default
      end
    end # }}}

    it "handles custom methods" do # {{{
      User.respond_to?(:popular).should be_true
      User.respond_to?(:foobar).should be_true
      User.respond_to?(:from_default).should be_true
    end # }}}

    it "handles custom GET requests" do # {{{
      @users = User.popular
      @users.length.should == 2
      @users.first.id.should == 1
    end # }}}

    it "handles custom POST requests" do # {{{
      @user = User.from_default(:name => "Tobias Fünke")
      @user.id.should be_true
    end # }}}
  end
end
