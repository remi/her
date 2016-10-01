# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe Her::Model::Parse do
  context "when include_root_in_json is set" do
    before do
      Her::API.setup url: "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
      end

      Her::API.default_api.connection.adapter :test do |stub|
        stub.post("/users") { |env| [200, {}, { user: { id: 1, fullname: params(env)[:user][:fullname] } }.to_json] }
        stub.post("/users/admins") { |env| [200, {}, { user: { id: 1, fullname: params(env)[:user][:fullname] } }.to_json] }
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
        @new_user = Foo::User.new(fullname: "Tobias Fünke")
        expect(@new_user.to_params).to eq(user: { fullname: "Tobias Fünke" })
      end

      it "wraps params in the element name in `.create`" do
        @new_user = Foo::User.admins(fullname: "Tobias Fünke")
        expect(@new_user.fullname).to eq("Tobias Fünke")
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
        @new_user = Foo::User.new(fullname: "Tobias Fünke")
        expect(@new_user.to_params).to eq(person: { fullname: "Tobias Fünke" })
      end
    end

    context "in the parent class" do
      before do
        spawn_model("Foo::Model") { include_root_in_json true }

        class User < Foo::Model; end
        @spawned_models << :User
      end

      it "wraps params with the class name" do
        @new_user = User.new(fullname: "Tobias Fünke")
        expect(@new_user.to_params).to eq(user: { fullname: "Tobias Fünke" })
      end
    end
  end

  context "when parse_root_in_json is set" do
    before do
      Her::API.setup url: "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
      end
    end

    context "to true" do
      before do
        Her::API.default_api.connection.adapter :test do |stub|
          stub.post("/users") { [200, {}, { user: { id: 1, fullname: "Lindsay Fünke" } }.to_json] }
          stub.get("/users") { [200, {}, [{ user: { id: 1, fullname: "Lindsay Fünke" } }].to_json] }
          stub.get("/users/admins") { [200, {}, [{ user: { id: 1, fullname: "Lindsay Fünke" } }].to_json] }
          stub.get("/users/1") { [200, {}, { user: { id: 1, fullname: "Lindsay Fünke" } }.to_json] }
          stub.put("/users/1") { [200, {}, { user: { id: 1, fullname: "Tobias Fünke Jr." } }.to_json] }
        end

        spawn_model("Foo::User") do
          parse_root_in_json true
          custom_get :admins
        end
      end

      it "parse the data from the JSON root element after .create" do
        @new_user = Foo::User.create(fullname: "Lindsay Fünke")
        expect(@new_user.fullname).to eq("Lindsay Fünke")
      end

      it "parse the data from the JSON root element after an arbitrary HTTP request" do
        @new_user = Foo::User.admins
        expect(@new_user.first.fullname).to eq("Lindsay Fünke")
      end

      it "parse the data from the JSON root element after .all" do
        @users = Foo::User.all
        expect(@users.first.fullname).to eq("Lindsay Fünke")
      end

      it "parse the data from the JSON root element after .find" do
        @user = Foo::User.find(1)
        expect(@user.fullname).to eq("Lindsay Fünke")
      end

      it "parse the data from the JSON root element after .save" do
        @user = Foo::User.find(1)
        @user.fullname = "Tobias Fünke"
        @user.save
        expect(@user.fullname).to eq("Tobias Fünke Jr.")
      end
    end

    context "to a symbol" do
      before do
        Her::API.default_api.connection.adapter :test do |stub|
          stub.post("/users") { [200, {}, { person: { id: 1, fullname: "Lindsay Fünke" } }.to_json] }
        end

        spawn_model("Foo::User") { parse_root_in_json :person }
      end

      it "parse the data with the symbol" do
        @new_user = Foo::User.create(fullname: "Lindsay Fünke")
        expect(@new_user.fullname).to eq("Lindsay Fünke")
      end
    end

    context "in the parent class" do
      before do
        Her::API.default_api.connection.adapter :test do |stub|
          stub.post("/users") { [200, {}, { user: { id: 1, fullname: "Lindsay Fünke" } }.to_json] }
          stub.get("/users") { [200, {}, { users: [{ id: 1, fullname: "Lindsay Fünke" }] }.to_json] }
        end

        spawn_model("Foo::Model") { parse_root_in_json true, format: :active_model_serializers }
        class User < Foo::Model
          collection_path "/users"
        end

        @spawned_models << :User
      end

      it "parse the data with the symbol" do
        @new_user = User.create(fullname: "Lindsay Fünke")
        expect(@new_user.fullname).to eq("Lindsay Fünke")
      end

      it "parses the collection of data" do
        @users = User.all
        expect(@users.first.fullname).to eq("Lindsay Fünke")
      end
    end

    context "to true with format: :active_model_serializers" do
      before do
        Her::API.default_api.connection.adapter :test do |stub|
          stub.post("/users") { [200, {}, { user: { id: 1, fullname: "Lindsay Fünke" } }.to_json] }
          stub.get("/users") { [200, {}, { users: [{ id: 1, fullname: "Lindsay Fünke" }] }.to_json] }
          stub.get("/users/admins") { [200, {}, { users: [{ id: 1, fullname: "Lindsay Fünke" }] }.to_json] }
          stub.get("/users/1") { [200, {}, { user: { id: 1, fullname: "Lindsay Fünke" } }.to_json] }
          stub.put("/users/1") { [200, {}, { user: { id: 1, fullname: "Tobias Fünke Jr." } }.to_json] }
        end

        spawn_model("Foo::User") do
          parse_root_in_json true, format: :active_model_serializers
          custom_get :admins
        end
      end

      it "parse the data from the JSON root element after .create" do
        @new_user = Foo::User.create(fullname: "Lindsay Fünke")
        expect(@new_user.fullname).to eq("Lindsay Fünke")
      end

      it "parse the data from the JSON root element after an arbitrary HTTP request" do
        @users = Foo::User.admins
        expect(@users.first.fullname).to eq("Lindsay Fünke")
      end

      it "parse the data from the JSON root element after .all" do
        @users = Foo::User.all
        expect(@users.first.fullname).to eq("Lindsay Fünke")
      end

      it "parse the data from the JSON root element after .find" do
        @user = Foo::User.find(1)
        expect(@user.fullname).to eq("Lindsay Fünke")
      end

      it "parse the data from the JSON root element after .save" do
        @user = Foo::User.find(1)
        @user.fullname = "Tobias Fünke"
        @user.save
        expect(@user.fullname).to eq("Tobias Fünke Jr.")
      end
    end
  end

  context "when to_params is set" do
    before do
      Her::API.setup url: "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.post("/users") { |env| ok! id: 1, fullname: params(env)["fullname"] }
        end
      end

      spawn_model "Foo::User" do
        def to_params
          { fullname: "Lindsay Fünke" }
        end
      end
    end

    it "changes the request parameters for one-line resource creation" do
      @user = Foo::User.create(fullname: "Tobias Fünke")
      expect(@user.fullname).to eq("Lindsay Fünke")
    end

    it "changes the request parameters for Model.new + #save" do
      @user = Foo::User.new(fullname: "Tobias Fünke")
      @user.save
      expect(@user.fullname).to eq("Lindsay Fünke")
    end
  end

  context "when parse_root_in_json set json_api to true" do
    before do
      Her::API.setup url: "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users") { [200, {}, { users: [{ id: 1, fullname: "Lindsay Fünke" }] }.to_json] }
          stub.get("/users/admins") { [200, {}, { users: [{ id: 1, fullname: "Lindsay Fünke" }] }.to_json] }
          stub.get("/users/1") { [200, {}, { users: [{ id: 1, fullname: "Lindsay Fünke" }] }.to_json] }
          stub.post("/users") { [200, {}, { users: [{ fullname: "Lindsay Fünke" }] }.to_json] }
          stub.put("/users/1") { [200, {}, { users: [{ id: 1, fullname: "Tobias Fünke Jr." }] }.to_json] }
        end
      end

      spawn_model("Foo::User") do
        parse_root_in_json true, format: :json_api
        include_root_in_json true
        custom_get :admins
      end
    end

    it "parse the data from the JSON root element after .create" do
      @new_user = Foo::User.create(fullname: "Lindsay Fünke")
      expect(@new_user.fullname).to eq("Lindsay Fünke")
    end

    it "parse the data from the JSON root element after an arbitrary HTTP request" do
      @new_user = Foo::User.admins
      expect(@new_user.first.fullname).to eq("Lindsay Fünke")
    end

    it "parse the data from the JSON root element after .all" do
      @users = Foo::User.all
      expect(@users.first.fullname).to eq("Lindsay Fünke")
    end

    it "parse the data from the JSON root element after .find" do
      @user = Foo::User.find(1)
      expect(@user.fullname).to eq("Lindsay Fünke")
    end

    it "parse the data from the JSON root element after .save" do
      @user = Foo::User.find(1)
      @user.fullname = "Tobias Fünke"
      @user.save
      expect(@user.fullname).to eq("Tobias Fünke Jr.")
    end

    it "parse the data from the JSON root element after new/save" do
      @user = Foo::User.new
      @user.fullname = "Lindsay Fünke (before save)"
      @user.save
      expect(@user.fullname).to eq("Lindsay Fünke")
    end
  end

  context "when include_root_in_json set json_api" do
    before do
      Her::API.setup url: "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
      end

      Her::API.default_api.connection.adapter :test do |stub|
        stub.post("/users") { |env| [200, {}, { users: [{ id: 1, fullname: params(env)[:users][:fullname] }] }.to_json] }
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
        @new_user = Foo::User.new(fullname: "Tobias Fünke")
        expect(@new_user.to_params).to eq(users: [{ fullname: "Tobias Fünke" }])
      end

      it "wraps params in the element name in `.where`" do
        @new_user = Foo::User.where(fullname: "Tobias Fünke").build
        expect(@new_user.fullname).to eq("Tobias Fünke")
      end
    end
  end

  context "when send_only_modified_attributes is set" do
    before do
      Her::API.setup url: "https://api.example.com", send_only_modified_attributes: true do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
      end

      Her::API.default_api.connection.adapter :test do |stub|
        stub.get("/users/1") { [200, {}, { id: 1, first_name: "Gooby", last_name: "Pls" }.to_json] }
      end

      spawn_model "Foo::User" do
        include_root_in_json true
      end
    end

    it "only sends the attributes that were modified" do
      user = Foo::User.find 1
      user.first_name = "Someone"
      expect(user.to_params).to eql(user: { first_name: "Someone" })
    end
  end
end
