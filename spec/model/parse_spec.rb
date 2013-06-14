# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe Her::Model::Parse do
  context "when include_root_in_json is set" do
    before do
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
      end

      Her::API.default_api.connection.adapter :test do |stub|
        stub.post("/users") { |env| [200, {}, { :user => { :id => 1, :fullname => params(env)[:user][:fullname] } }.to_json] }
        stub.post("/users/admins") { |env| [200, {}, { :user => { :id => 1, :fullname => params(env)[:user][:fullname] } }.to_json] }
      end
    end

    context "to true" do
      before do
        spawn_model "Foo::User" do
          include_root_in_json true
          parse_root_in_json true
          custom_post :admins
        end
      end

      it "wraps params in the element name in `to_params`" do
        @new_user = Foo::User.new(:fullname => "Tobias Fünke")
        @new_user.to_params.should == { :user => { :fullname => "Tobias Fünke" } }
      end

      it "wraps params in the element name in `.create`" do
        @new_user = Foo::User.admins(:fullname => "Tobias Fünke")
        @new_user.fullname.should == "Tobias Fünke"
      end
    end

    context "to a symbol" do
      before do
        spawn_model "Foo::User" do
          include_root_in_json :person
          parse_root_in_json :person
        end
      end

      it "wraps params in the specified value" do
        @new_user = Foo::User.new(:fullname => "Tobias Fünke")
        @new_user.to_params.should == { :person => { :fullname => "Tobias Fünke" } }
      end
    end

    context "in the parent class" do
      before do
        spawn_model("Foo::Model") { include_root_in_json true }

        class User < Foo::Model; end
        @spawned_models << :User
      end

      it "wraps params with the class name" do
        @new_user = User.new(:fullname => "Tobias Fünke")
        @new_user.to_params.should == { :user => { :fullname => "Tobias Fünke" } }
      end
    end
  end

  context "when parse_root_in_json is set" do
    before do
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
      end
    end

    context "to true" do
      before do
        Her::API.default_api.connection.adapter :test do |stub|
          stub.post("/users") { |env| [200, {}, { :user => { :id => 1, :fullname => "Lindsay Fünke" } }.to_json] }
          stub.get("/users") { |env| [200, {}, [{ :user => { :id => 1, :fullname => "Lindsay Fünke" } }].to_json] }
          stub.get("/users/admins") { |env| [200, {}, [{ :user => { :id => 1, :fullname => "Lindsay Fünke" } }].to_json] }
          stub.get("/users/1") { |env| [200, {}, { :user => { :id => 1, :fullname => "Lindsay Fünke" } }.to_json] }
          stub.put("/users/1") { |env| [200, {}, { :user => { :id => 1, :fullname => "Tobias Fünke Jr." } }.to_json] }
        end

        spawn_model("Foo::User") do
          parse_root_in_json true
          custom_get :admins
        end
      end

      it "parse the data from the JSON root element after .create" do
        @new_user = Foo::User.create(:fullname => "Lindsay Fünke")
        @new_user.fullname.should == "Lindsay Fünke"
      end

      it "parse the data from the JSON root element after an arbitrary HTTP request" do
        @new_user = Foo::User.admins
        @new_user.first.fullname.should == "Lindsay Fünke"
      end

      it "parse the data from the JSON root element after .all" do
        @users = Foo::User.all
        @users.first.fullname.should == "Lindsay Fünke"
      end

      it "parse the data from the JSON root element after .find" do
        @user = Foo::User.find(1)
        @user.fullname.should == "Lindsay Fünke"
      end

      it "parse the data from the JSON root element after .save" do
        @user = Foo::User.find(1)
        @user.fullname = "Tobias Fünke"
        @user.save
        @user.fullname.should == "Tobias Fünke Jr."
      end
    end

    context "to a symbol" do
      before do
        Her::API.default_api.connection.adapter :test do |stub|
          stub.post("/users") { |env| [200, {}, { :person => { :id => 1, :fullname => "Lindsay Fünke" } }.to_json] }
        end

        spawn_model("Foo::User") { parse_root_in_json :person }
      end

      it "parse the data with the symbol" do
        @new_user = Foo::User.create(:fullname => "Lindsay Fünke")
        @new_user.fullname.should == "Lindsay Fünke"
      end
    end

    context "in the parent class" do
      before do
        Her::API.default_api.connection.adapter :test do |stub|
          stub.post("/users") { |env| [200, {}, { :user => { :id => 1, :fullname => "Lindsay Fünke" } }.to_json] }
        end

        spawn_model("Foo::Model") { parse_root_in_json true }
        class User < Foo::Model
          collection_path "/users"
        end

        @spawned_models << :User
      end

      it "parse the data with the symbol" do
        @new_user = User.create(:fullname => "Lindsay Fünke")
        @new_user.fullname.should == "Lindsay Fünke"
      end
    end
  end

  context "when to_params is set" do
    before do
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.post("/users") { |env| ok! :id => 1, :fullname => params(env)['fullname'] }
        end
      end

      spawn_model "Foo::User" do
        def to_params
          { :fullname => "Lindsay Fünke" }
        end
      end
    end

    it "changes the request parameters for one-line resource creation" do
      @user = Foo::User.create(:fullname => "Tobias Fünke")
      @user.fullname.should == "Lindsay Fünke"
    end

    it "changes the request parameters for Model.new + #save" do
      @user = Foo::User.new(:fullname => "Tobias Fünke")
      @user.save
      @user.fullname.should == "Lindsay Fünke"
    end
  end

  context "when parse_root_in_json set jsonapi to true" do
    before do
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
      end

      Her::API.default_api.connection.adapter :test do |stub|
        stub.get("/users") { |env| [200, {},  { :users => [{ :id => 1, :fullname => "Lindsay Fünke" }] }.to_json] }
        stub.get("/users/admins") { |env| [200, {}, { :users => [{ :id => 1, :fullname => "Lindsay Fünke" }] }.to_json] }
        stub.get("/users/1") { |env| [200, {}, { :users => [{ :id => 1, :fullname => "Lindsay Fünke" }] }.to_json] }
        stub.post("/users") { |env| [200, {}, { :users => [{ :id => 1, :fullname => "Lindsay Fünke" }] }.to_json] }
        stub.put("/users/1") { |env| [200, {}, { :users => [{ :id => 1, :fullname => "Tobias Fünke Jr." }] }.to_json] }
      end

      spawn_model("Foo::User") do
        parse_root_in_json true, :format => :jsonapi
        custom_get :admins
      end
    end

    it "parse the data from the JSON root element after .create" do
      @new_user = Foo::User.create(:fullname => "Lindsay Fünke")
      @new_user.fullname.should == "Lindsay Fünke"
    end

    it "parse the data from the JSON root element after an arbitrary HTTP request" do
      @new_user = Foo::User.admins
      @new_user.first.fullname.should == "Lindsay Fünke"
    end

    it "parse the data from the JSON root element after .all" do
      @users = Foo::User.all
      @users.first.fullname.should == "Lindsay Fünke"
    end

    it "parse the data from the JSON root element after .find" do
      @user = Foo::User.find(1)
      @user.fullname.should == "Lindsay Fünke"
    end

    it "parse the data from the JSON root element after .save" do
      @user = Foo::User.find(1)
      @user.fullname = "Tobias Fünke"
      @user.save
      @user.fullname.should == "Tobias Fünke Jr."
    end

    it "parse the data from the JSON root element after new/save" do
      @user = Foo::User.new
      @user.fullname = "Lindsay Fünke (before save)"
      @user.save
      @user.fullname.should == "Lindsay Fünke"
    end
  end

  context "when include_root_in_json set jsonapi to true" do
    before do
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
      end

      Her::API.default_api.connection.adapter :test do |stub|
        stub.post("/users") { |env| [200, {}, { :users => [{ :id => 1, :fullname => params(env)[:users][:fullname] }] }.to_json] }
        stub.post("/users/admins") { |env| [200, {}, { :users => [{ :id => 1, :fullname => params(env)[:users][:fullname] }] }.to_json] }
      end
    end

    context "to true" do
      before do
        spawn_model "Foo::User" do
          include_root_in_json true, format: :jsonapi
          custom_post :admins
        end
      end

      it "wraps params in the element name in `to_params`" do
        @new_user = Foo::User.new(:fullname => "Tobias Fünke")
        @new_user.to_params.should == { :users => [{ :fullname => "Tobias Fünke" }] }
      end

      # it "wraps params in the element name in `.create`" do
      #   @new_user = Foo::User.admins(:fullname => "Tobias Fünke")
      #   @new_user.fullname.should == "Tobias Fünke"
      # end
    end
  end
end
