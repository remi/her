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

      it "inherits attributes from parent class" do
        spawn_model "Foo::ChildUser", super_class: Foo::User do
        end

        expect(Foo::ChildUser).to be_include_root_in_json
      end

      it "allows `include_root_in_json` to be set to `false` on a child model" do
        spawn_model "Foo::ChildUser", super_class: Foo::User do
          include_root_in_json false
        end

        expect(Foo::ChildUser).to_not be_include_root_in_json
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

    context "to false" do
      before do
        spawn_model "Foo::User" do
          include_root_in_json false
        end
      end

      it "inherits attributes from parent class" do
        spawn_model "Foo::ChildUser", super_class: Foo::User do
        end

        expect(Foo::ChildUser).to_not be_include_root_in_json
      end

      it "allows `include_root_in_json` to be set to `true` on a child model" do
        spawn_model "Foo::ChildUser", super_class: Foo::User do
          include_root_in_json true
        end

        expect(Foo::ChildUser).to be_include_root_in_json
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

  context "when include_root_in_embedded_json is set" do
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
          include_root_in_embedded_json true
          parse_root_in_json true
          custom_post :admins
        end
      end

      it "inherits attributes from parent class" do
        spawn_model "Foo::ChildUser", super_class: Foo::User do
        end

        expect(Foo::ChildUser).to be_include_root_in_embedded_json
      end

      it "allows `include_root_in_embedded_json` to be set to `false` on a child model" do
        spawn_model "Foo::ChildUser", super_class: Foo::User do
          include_root_in_embedded_json false
        end

        expect(Foo::ChildUser).to_not be_include_root_in_embedded_json
      end

      it "wraps params in the element name in `to_embedded_params`" do
        @new_user = Foo::User.new(fullname: "Tobias Fünke")
        expect(@new_user.to_embedded_params).to eq(user: { fullname: "Tobias Fünke" })
      end
    end

    context "to false" do
      before do
        spawn_model "Foo::User" do
          include_root_in_embedded_json false
        end
      end

      it "inherits attributes from parent class" do
        spawn_model "Foo::ChildUser", super_class: Foo::User do
        end

        expect(Foo::ChildUser).to_not be_include_root_in_embedded_json
      end

      it "allows `include_root_in_embedded_json` to be set to `true` on a child model" do
        spawn_model "Foo::ChildUser", super_class: Foo::User do
          include_root_in_embedded_json true
        end

        expect(Foo::ChildUser).to be_include_root_in_embedded_json
      end
    end

    context "to a symbol" do
      before do
        spawn_model "Foo::User" do
          include_root_in_embedded_json :person
          parse_root_in_json :person
        end
      end

      it "wraps params in the specified value" do
        @new_user = Foo::User.new(fullname: "Tobias Fünke")
        expect(@new_user.to_embedded_params).to eq(person: { fullname: "Tobias Fünke" })
      end
    end

    context "in the parent class" do
      before do
        spawn_model("Foo::Model") { include_root_in_embedded_json true }

        class User < Foo::Model; end
        @spawned_models << :User
      end

      it "wraps params with the class name" do
        @new_user = User.new(fullname: "Tobias Fünke")
        expect(@new_user.to_embedded_params).to eq(user: { fullname: "Tobias Fünke" })
      end
    end
  end

  context "when `request_new_object_on_build` is set" do
    context "to true" do
      before do
        spawn_model "Foo::User" do
          request_new_object_on_build true
        end
      end

      it "inherits attributes from parent class" do
        spawn_model "Foo::ChildUser", super_class: Foo::User do
        end

        expect(Foo::ChildUser).to be_request_new_object_on_build
      end

      it "allows `request_new_object_on_build` to be set to `false` on a child model" do
        spawn_model "Foo::ChildUser", super_class: Foo::User do
          request_new_object_on_build false
        end

        expect(Foo::ChildUser).to_not be_request_new_object_on_build
      end
    end

    context "to false" do
      before do
        spawn_model "Foo::User" do
          request_new_object_on_build false
        end
      end

      it "inherits attributes from parent class" do
        spawn_model "Foo::ChildUser", super_class: Foo::User do
        end

        expect(Foo::ChildUser).to_not be_request_new_object_on_build
      end

      it "allows `request_new_object_on_build` to be set to `true` on a child model" do
        spawn_model "Foo::ChildUser", super_class: Foo::User do
          request_new_object_on_build true
        end

        expect(Foo::ChildUser).to be_request_new_object_on_build
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

      it "inherits attributes from parent class" do
        spawn_model "Foo::ChildUser", super_class: Foo::User do
        end

        expect(Foo::ChildUser).to be_parse_root_in_json
      end

      it "allows `parse_root_in_json` to be set to `false` on a child model" do
        spawn_model "Foo::ChildUser", super_class: Foo::User do
          parse_root_in_json false
        end

        expect(Foo::ChildUser).to_not be_parse_root_in_json
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

    context "to false" do
      before do
        spawn_model "Foo::User" do
          parse_root_in_json false
        end
      end

      it "inherits attributes from parent class" do
        spawn_model "Foo::ChildUser", super_class: Foo::User do
        end

        expect(Foo::ChildUser).to_not be_parse_root_in_json
      end

      it "allows `parse_root_in_json` to be set to `true` on a child model" do
        spawn_model "Foo::ChildUser", super_class: Foo::User do
          parse_root_in_json true
        end

        expect(Foo::ChildUser).to be_parse_root_in_json
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
        expect(@new_user.id).to eq(1)
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

  context 'when passed a non-Her ActiveModel instance' do
    before do
      klass = Class.new do
        include ActiveModel::Serialization

        def attributes
          { 'name' => nil }
        end

        def name
          'foo'
        end
      end

      @model = klass.new

      Her::API.setup
      spawn_model 'Foo::User'
    end

    it 'serializes the instance in `to_params`' do
      attributes = { model: @model }
      user = Foo::User.new(attributes)
      expect(user.to_params).to eq(model: { name: 'foo' })
    end
  end

  context "when attribute uses the same name as root element" do
    before do
      Her::API.setup url: "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
      end

      Her::API.default_api.connection.adapter :test do |stub|
        stub.post("/users") { |env| [200, {}, { user: "foobar", id: 1, fullname: params(env)[:fullname] }.to_json] }
      end

      spawn_model "Foo::User"
    end

    it "parses as attribute instead of root element" do
      user = Foo::User.create(fullname: "barfoo")
      expect(user.fullname).to eq "barfoo"
      expect(user.user).to eq "foobar"
    end
  end
end
