# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe Her::Model::Paths do
  context "building request paths" do
    context "simple model" do
      before do
        spawn_model "Foo::User"
      end

      describe "#request_path" do
        it "builds paths with defaults" do
          expect(Foo::User.new(id: "foo").request_path).to eq("users/foo")
          expect(Foo::User.new(id: nil).request_path).to eq("users")
          expect(Foo::User.new.request_path).to eq("users")
        end

        it "builds paths with custom collection path" do
          Foo::User.collection_path "/utilisateurs"
          expect(Foo::User.new(id: "foo").request_path).to eq("/utilisateurs/foo")
          expect(Foo::User.new.request_path).to eq("/utilisateurs")
        end

        it "builds paths with custom relative collection path" do
          Foo::User.collection_path "utilisateurs"
          expect(Foo::User.new(id: "foo").request_path).to eq("utilisateurs/foo")
          expect(Foo::User.new.request_path).to eq("utilisateurs")
        end

        it "builds paths with custom collection path with multiple variables" do
          Foo::User.collection_path "/organizations/:organization_id/utilisateurs"

          expect(Foo::User.new(id: "foo").request_path(_organization_id: "acme")).to eq("/organizations/acme/utilisateurs/foo")
          expect(Foo::User.new.request_path(_organization_id: "acme")).to eq("/organizations/acme/utilisateurs")

          expect(Foo::User.new(id: "foo", organization_id: "acme").request_path).to eq("/organizations/acme/utilisateurs/foo")
          expect(Foo::User.new(organization_id: "acme").request_path).to eq("/organizations/acme/utilisateurs")
        end

        it "builds paths with custom relative collection path with multiple variables" do
          Foo::User.collection_path "organizations/:organization_id/utilisateurs"

          expect(Foo::User.new(id: "foo").request_path(_organization_id: "acme")).to eq("organizations/acme/utilisateurs/foo")
          expect(Foo::User.new.request_path(_organization_id: "acme")).to eq("organizations/acme/utilisateurs")

          expect(Foo::User.new(id: "foo", organization_id: "acme").request_path).to eq("organizations/acme/utilisateurs/foo")
          expect(Foo::User.new(organization_id: "acme").request_path).to eq("organizations/acme/utilisateurs")
        end

        it "builds paths with custom item path" do
          Foo::User.resource_path "/utilisateurs/:id"
          expect(Foo::User.new(id: "foo").request_path).to eq("/utilisateurs/foo")
          expect(Foo::User.new.request_path).to eq("users")
        end

        it "builds paths with custom relative item path" do
          Foo::User.resource_path "utilisateurs/:id"
          expect(Foo::User.new(id: "foo").request_path).to eq("utilisateurs/foo")
          expect(Foo::User.new.request_path).to eq("users")
        end

        it "raises exceptions when building a path without required custom variables" do
          Foo::User.collection_path "/organizations/:organization_id/utilisateurs"
          expect { Foo::User.new(id: "foo").request_path }.to raise_error(Her::Errors::PathError, "Missing :_organization_id parameter to build the request path. Path is `/organizations/:organization_id/utilisateurs/:id`. Parameters are `{:id=>\"foo\"}`.")
        end

        it "escapes the variable values" do
          Foo::User.collection_path "organizations/:organization_id/utilisateurs"
          expect(Foo::User.new(id: "Привет").request_path(_organization_id: "лол")).to eq("organizations/%D0%BB%D0%BE%D0%BB/utilisateurs/%D0%9F%D1%80%D0%B8%D0%B2%D0%B5%D1%82")
          expect(Foo::User.new(organization_id: "лол", id: "Привет").request_path).to eq("organizations/%D0%BB%D0%BE%D0%BB/utilisateurs/%D0%9F%D1%80%D0%B8%D0%B2%D0%B5%D1%82")
        end
      end
    end

    context "simple model with multiple words" do
      before do
        spawn_model "Foo::AdminUser"
      end

      describe "#request_path" do
        it "builds paths with defaults" do
          expect(Foo::AdminUser.new(id: "foo").request_path).to eq("admin_users/foo")
          expect(Foo::AdminUser.new.request_path).to eq("admin_users")
        end

        it "builds paths with custom collection path" do
          Foo::AdminUser.collection_path "/users"
          expect(Foo::AdminUser.new(id: "foo").request_path).to eq("/users/foo")
          expect(Foo::AdminUser.new.request_path).to eq("/users")
        end

        it "builds paths with custom relative collection path" do
          Foo::AdminUser.collection_path "users"
          expect(Foo::AdminUser.new(id: "foo").request_path).to eq("users/foo")
          expect(Foo::AdminUser.new.request_path).to eq("users")
        end

        it "builds paths with custom collection path with multiple variables" do
          Foo::AdminUser.collection_path "/organizations/:organization_id/users"
          expect(Foo::AdminUser.new(id: "foo").request_path(_organization_id: "acme")).to eq("/organizations/acme/users/foo")
          expect(Foo::AdminUser.new.request_path(_organization_id: "acme")).to eq("/organizations/acme/users")
        end

        it "builds paths with custom relative collection path with multiple variables" do
          Foo::AdminUser.collection_path "organizations/:organization_id/users"
          expect(Foo::AdminUser.new(id: "foo").request_path(_organization_id: "acme")).to eq("organizations/acme/users/foo")
          expect(Foo::AdminUser.new.request_path(_organization_id: "acme")).to eq("organizations/acme/users")
        end

        it "builds paths with custom item path" do
          Foo::AdminUser.resource_path "/users/:id"
          expect(Foo::AdminUser.new(id: "foo").request_path).to eq("/users/foo")
          expect(Foo::AdminUser.new.request_path).to eq("admin_users")
        end

        it "builds paths with custom relative item path" do
          Foo::AdminUser.resource_path "users/:id"
          expect(Foo::AdminUser.new(id: "foo").request_path).to eq("users/foo")
          expect(Foo::AdminUser.new.request_path).to eq("admin_users")
        end

        it "raises exceptions when building a path without required custom variables" do
          Foo::AdminUser.collection_path "/organizations/:organization_id/users"
          expect { Foo::AdminUser.new(id: "foo").request_path }.to raise_error(Her::Errors::PathError, "Missing :_organization_id parameter to build the request path. Path is `/organizations/:organization_id/users/:id`. Parameters are `{:id=>\"foo\"}`.")
        end

        it "raises exceptions when building a relative path without required custom variables" do
          Foo::AdminUser.collection_path "organizations/:organization_id/users"
          expect { Foo::AdminUser.new(id: "foo").request_path }.to raise_error(Her::Errors::PathError, "Missing :_organization_id parameter to build the request path. Path is `organizations/:organization_id/users/:id`. Parameters are `{:id=>\"foo\"}`.")
        end
      end
    end

    context "children model" do
      before do
        Her::API.setup url: "https://api.example.com" do |builder|
          builder.use Her::Middleware::FirstLevelParseJSON
          builder.use Faraday::Request::UrlEncoded
          builder.adapter :test do |stub|
            stub.get("/users/foo") { [200, {}, { id: "foo" }.to_json] }
          end
        end

        spawn_model("Foo::Model") { include_root_in_json true }

        class User < Foo::Model; end
        @spawned_models << :User
      end

      it "builds path using the children model name" do
        expect(User.find("foo").id).to eq("foo")
        expect(User.find("foo").id).to eq("foo")
      end
    end

    context "nested model" do
      before do
        spawn_model "Foo::User"
      end

      describe "#request_path" do
        it "builds paths with defaults" do
          expect(Foo::User.new(id: "foo").request_path).to eq("users/foo")
          expect(Foo::User.new.request_path).to eq("users")
        end
      end
    end

    context "custom primary key" do
      before do
        spawn_model "User" do
          primary_key "UserId"
          resource_path "users/:UserId"
        end

        spawn_model "Customer" do
          primary_key :customer_id
          resource_path "customers/:id"
        end
      end

      describe "#request_path" do
        it "uses the correct primary key attribute" do
          expect(User.new(UserId: "foo").request_path).to eq("users/foo")
          expect(User.new(id: "foo").request_path).to eq("users")
        end

        it "replaces :id with the appropriate primary key" do
          expect(Customer.new(customer_id: "joe").request_path).to eq("customers/joe")
          expect(Customer.new(id: "joe").request_path).to eq("customers")
        end
      end
    end
  end

  context "making subdomain HTTP requests" do
    before do
      Her::API.setup url: "https://api.example.com/" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("organizations/2/users") { [200, {}, [{ id: 1, fullname: "Tobias Fünke", organization_id: 2 }, { id: 2, fullname: "Lindsay Fünke", organization_id: 2 }].to_json] }
          stub.post("organizations/2/users") { [200, {}, { id: 1, fullname: "Tobias Fünke", organization_id: 2 }.to_json] }
          stub.put("organizations/2/users/1") { [200, {}, { id: 1, fullname: "Lindsay Fünke", organization_id: 2 }.to_json] }
          stub.get("organizations/2/users/1") { [200, {}, { id: 1, fullname: "Tobias Fünke", organization_id: 2, active: true }.to_json] }
          stub.delete("organizations/2/users/1") { [200, {}, { id: 1, fullname: "Lindsay Fünke", organization_id: 2, active: false }.to_json] }
        end
      end

      spawn_model "Foo::User" do
        collection_path "organizations/:organization_id/users"
      end
    end

    describe "fetching a resource" do
      it "maps a single resource to a Ruby object" do
        @user = Foo::User.find(1, _organization_id: 2)
        expect(@user.id).to eq(1)
        expect(@user.fullname).to eq("Tobias Fünke")
      end

      it "maps a single resource using a scope to a Ruby object" do
        Foo::User.scope :for_organization, ->(o) { where(organization_id: o) }
        @user = Foo::User.for_organization(2).find(1)
        expect(@user.id).to eq(1)
        expect(@user.fullname).to eq("Tobias Fünke")
      end
    end

    describe "fetching a collection" do
      it "maps a collection of resources to an array of Ruby objects" do
        @users = Foo::User.where(_organization_id: 2).all
        expect(@users.length).to eq(2)
        expect(@users.first.fullname).to eq("Tobias Fünke")
      end
    end

    describe "handling new resource" do
      it "handles new resource" do
        @new_user = Foo::User.new(fullname: "Tobias Fünke", organization_id: 2)
        expect(@new_user.new?).to be_truthy

        @existing_user = Foo::User.find(1, _organization_id: 2)
        expect(@existing_user.new?).to be_falsey
      end
    end

    describe "creating resources" do
      it "handle one-line resource creation" do
        @user = Foo::User.create(fullname: "Tobias Fünke", organization_id: 2)
        expect(@user.id).to eq(1)
        expect(@user.fullname).to eq("Tobias Fünke")
      end

      it "handle resource creation through Model.new + #save" do
        @user = Foo::User.new(fullname: "Tobias Fünke", organization_id: 2)
        @user.save
        expect(@user.fullname).to eq("Tobias Fünke")
      end
    end

    context "updating resources" do
      it "handle resource data update without saving it" do
        @user = Foo::User.find(1, _organization_id: 2)
        expect(@user.fullname).to eq("Tobias Fünke")
        @user.fullname = "Kittie Sanchez"
        expect(@user.fullname).to eq("Kittie Sanchez")
      end

      it "handle resource update through the .update class method" do
        @user = Foo::User.save_existing(1, fullname: "Lindsay Fünke", organization_id: 2)
        expect(@user.fullname).to eq("Lindsay Fünke")
      end

      it "handle resource update through #save on an existing resource" do
        @user = Foo::User.find(1, _organization_id: 2)
        @user.fullname = "Lindsay Fünke"
        @user.save
        expect(@user.fullname).to eq("Lindsay Fünke")
      end
    end

    context "deleting resources" do
      it "handle resource deletion through the .destroy class method" do
        @user = Foo::User.destroy_existing(1, _organization_id: 2)
        expect(@user.active).to be_falsey
      end

      it "handle resource deletion through #destroy on an existing resource" do
        @user = Foo::User.find(1, _organization_id: 2)
        @user.destroy
        expect(@user.active).to be_falsey
      end
    end
  end

  context "making path HTTP requests" do
    before do
      Her::API.setup url: "https://example.com/api/" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/api/organizations/2/users") { [200, {}, [{ id: 1, fullname: "Tobias Fünke", organization_id: 2 }, { id: 2, fullname: "Lindsay Fünke", organization_id: 2 }].to_json] }
          stub.get("/api/organizations/2/users/1") { [200, {}, { id: 1, fullname: "Tobias Fünke", organization_id: 2, active: true }.to_json] }
        end
      end

      spawn_model "Foo::User" do
        collection_path "organizations/:organization_id/users"
      end
    end

    describe "fetching a resource" do
      it "maps a single resource to a Ruby object" do
        @user = Foo::User.find(1, _organization_id: 2)
        expect(@user.id).to eq(1)
        expect(@user.fullname).to eq("Tobias Fünke")
      end
    end

    describe "fetching a collection" do
      it "maps a collection of resources to an array of Ruby objects" do
        @users = Foo::User.where(_organization_id: 2).all
        expect(@users.length).to eq(2)
        expect(@users.first.fullname).to eq("Tobias Fünke")
      end
    end

    describe "fetching a resource with absolute path" do
      it "maps a single resource to a Ruby object" do
        Foo::User.resource_path "/api/" + Foo::User.resource_path
        @user = Foo::User.find(1, _organization_id: 2)
        expect(@user.id).to eq(1)
        expect(@user.fullname).to eq("Tobias Fünke")
      end
    end

    describe "fetching a collection with absolute path" do
      it "maps a collection of resources to an array of Ruby objects" do
        Foo::User.collection_path "/api/" + Foo::User.collection_path
        @users = Foo::User.where(_organization_id: 2).all
        expect(@users.length).to eq(2)
        expect(@users.first.fullname).to eq("Tobias Fünke")
      end
    end
  end
end
