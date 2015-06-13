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
          stub.get("/users") { |env| [200, {}, { :users => [ { :id => 1, :fullname => "Lindsay Fünke" } ] }.to_json] }
        end

        spawn_model("Foo::Model") { parse_root_in_json true, format: :active_model_serializers }
        class User < Foo::Model
          collection_path "/users"
        end

        @spawned_models << :User
      end

      it "parse the data with the symbol" do
        @new_user = User.create(:fullname => "Lindsay Fünke")
        @new_user.fullname.should == "Lindsay Fünke"
      end

      it "parses the collection of data" do
        @users = User.all
        @users.first.fullname.should == "Lindsay Fünke"
      end
    end

    context "to true with :format => :active_model_serializers" do
      before do
        Her::API.default_api.connection.adapter :test do |stub|
          stub.post("/users") { |env| [200, {}, { :user => { :id => 1, :fullname => "Lindsay Fünke" } }.to_json] }
          stub.get("/users") { |env| [200, {}, { :users => [ { :id => 1, :fullname => "Lindsay Fünke" } ] }.to_json] }
          stub.get("/users/admins") { |env| [200, {}, { :users => [ { :id => 1, :fullname => "Lindsay Fünke" } ] }.to_json] }
          stub.get("/users/1") { |env| [200, {}, { :user => { :id => 1, :fullname => "Lindsay Fünke" } }.to_json] }
          stub.put("/users/1") { |env| [200, {}, { :user => { :id => 1, :fullname => "Tobias Fünke Jr." } }.to_json] }
        end

        spawn_model("Foo::User") do
          parse_root_in_json true, :format => :active_model_serializers
          custom_get :admins
        end
      end

      it "parse the data from the JSON root element after .create" do
        @new_user = Foo::User.create(:fullname => "Lindsay Fünke")
        @new_user.fullname.should == "Lindsay Fünke"
      end

      it "parse the data from the JSON root element after an arbitrary HTTP request" do
        @users = Foo::User.admins
        @users.first.fullname.should == "Lindsay Fünke"
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

  context "when parse_root_in_json set json_api to true" do
    before do
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users") { |env| [200, {},  { :users => [{ :id => 1, :fullname => "Lindsay Fünke" }] }.to_json] }
          stub.get("/users/admins") { |env| [200, {}, { :users => [{ :id => 1, :fullname => "Lindsay Fünke" }] }.to_json] }

          # json api
          stub.get("/users/1") { |env| [200, {}, { :users => { :id => 1, :fullname => "Lindsay Fünke" } }.to_json] }
          stub.post("/users") { |env| [200, {}, { :users => { :fullname => "Lindsay Fünke" } }.to_json] }
          stub.put("/users/1") { |env| [200, {}, { :users => { :id => 1, :fullname => "Tobias Fünke Jr." } }.to_json] }

          # make sure json api changes maintain backwards compatibility
          stub.get("/managers/1") { |env| [200, {}, { :managers => [{ :id => 1, :fullname => "jimmy mcnulty" }] }.to_json] }
          stub.post("/managers") { |env|  [200, {}, { :managers => [{ :fullname => "bob loblaw" }] }.to_json] }
          stub.put("/managers/1") { |env| [200, {}, { :managers => [{ :id => 1, :fullname => "bunk moreland" }] }.to_json] }
        end
      end

      spawn_model("Foo::Manager") do
        parse_root_in_json true, :format => :json_api
        include_root_in_json true
        custom_get :admins
      end

      spawn_model("Foo::User") do
        parse_root_in_json true, :format => :json_api
        include_root_in_json true
        custom_get :admins
      end
    end

    it "parses the data from the JSON root element after .create even if wrapped in array" do
      @new_manager = Foo::Manager.create(:fullname => "bob loblaw")
      @new_manager.fullname.should == "bob loblaw"
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

    it "parses the data from the JSON root element after .find even if wrapped in an array" do
      @manager = Foo::Manager.find(1)
      @manager.fullname.should == "jimmy mcnulty"
    end

    it "parses the data from the JSON root element after .find" do
      @user = Foo::User.find(1)
      @user.fullname.should == "Lindsay Fünke"
    end

    it "parses the data from the JSON root element after .save even if wrapped in array" do
      @manager = Foo::Manager.find(1)
      @manager.save
      @manager.fullname.should == "bunk moreland"
    end

    it "parse the data from the JSON root element after .save" do
      @user = Foo::User.find(1)
      @user.fullname = "Tobias Fünke"
      @user.save
      @user.fullname.should == "Tobias Fünke Jr."
    end

    it "parse the data from the JSON root element after new/save if wrapped in array" do
      @manager = Foo::User.new
      @manager.fullname = "Lindsay Fünke (before save)"
      @manager.save
      @manager.fullname.should == "Lindsay Fünke"
    end

    it "parse the data from the JSON root element after new/save" do
      @manager = Foo::Manager.new
      @manager.fullname = "bob loblaw (before create)"
      @manager.save
      @manager.fullname.should == "bob loblaw"
    end
  end

  context "when include_root_in_json set json_api" do
    before do
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
      end

      Her::API.default_api.connection.adapter :test do |stub|
        stub.post("/users") { |env| [200, {}, { :users => { :id => 1, :fullname => params(env)[:users][:fullname] } }.to_json] }
      end
    end

    context "to true" do
      before do
        spawn_model "Foo::User" do
          include_root_in_json true
          parse_root_in_json true, format: :json_api
          custom_post :admins
        end
      end

      it "wraps params in the element name in `to_params`" do
        @new_user = Foo::User.new(:fullname => "Tobias Fünke")
        @new_user.to_params.should == { :users => [{ :fullname => "Tobias Fünke" }] }
      end

      it "wraps params in the element name in `.where`" do
        @new_user = Foo::User.where(:fullname => "Tobias Fünke").build
        @new_user.fullname.should == "Tobias Fünke"
      end
    end

    context "to true and wraps_single_elements set to false" do
      before do
        spawn_model "Foo::User" do
          include_root_in_json true, wrap_single_elements: false
          parse_root_in_json true, format: :json_api
          custom_post :admins
        end
      end

      it "wraps params in the element name in `to_params`" do
        @new_user = Foo::User.new(:fullname => "Tobias Fünke")
        @new_user.to_params.should == { :users => { :fullname => "Tobias Fünke" } }
      end

      it "wraps params in the element name in `.where`" do
        @new_user = Foo::User.where(:fullname => "Tobias Fünke").build
        @new_user.fullname.should == "Tobias Fünke"
      end
    end
  end

  context 'when send_only_modified_attributes is set' do
    before do
      Her::API.setup :url => "https://api.example.com", :send_only_modified_attributes => true do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
      end

      Her::API.default_api.connection.adapter :test do |stub|
        stub.get("/users/1") { |env| [200, {}, { :id => 1, :first_name => "Gooby", :last_name => "Pls" }.to_json] }
      end

      spawn_model "Foo::User" do
        include_root_in_json true
      end
    end

    it 'only sends the attributes that were modified' do
      user = Foo::User.find 1
      user.first_name = 'Someone'
      expect(user.to_params).to eql(:user => {:first_name => 'Someone'})
    end
  end
end
