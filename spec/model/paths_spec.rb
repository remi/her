# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe Her::Model::Paths do
  context "building request paths" do
    context "simple model" do
      before do
        spawn_model "Foo::User"
      end

      describe "#build_request_path" do
        it "builds paths with defaults" do
          Foo::User.build_request_path(:id => "foo").should == "users/foo"
          Foo::User.build_request_path(:id => nil).should == "users"
          Foo::User.build_request_path.should == "users"
        end

        it "builds paths with custom collection path" do
          Foo::User.collection_path "/utilisateurs"
          Foo::User.build_request_path(:id => "foo").should == "/utilisateurs/foo"
          Foo::User.build_request_path.should == "/utilisateurs"
        end

        it "builds paths with custom relative collection path" do
          Foo::User.collection_path "utilisateurs"
          Foo::User.build_request_path(:id => "foo").should == "utilisateurs/foo"
          Foo::User.build_request_path.should == "utilisateurs"
        end

        it "builds paths with custom collection path with multiple variables" do
          Foo::User.collection_path "/organizations/:organization_id/utilisateurs"

          Foo::User.build_request_path(:id => "foo", :_organization_id => "acme").should == "/organizations/acme/utilisateurs/foo"
          Foo::User.build_request_path(:_organization_id => "acme").should == "/organizations/acme/utilisateurs"

          Foo::User.build_request_path(:id => "foo", :organization_id => "acme").should == "/organizations/acme/utilisateurs/foo"
          Foo::User.build_request_path(:organization_id => "acme").should == "/organizations/acme/utilisateurs"
        end

        it "builds paths with custom relative collection path with multiple variables" do
          Foo::User.collection_path "organizations/:organization_id/utilisateurs"

          Foo::User.build_request_path(:id => "foo", :_organization_id => "acme").should == "organizations/acme/utilisateurs/foo"
          Foo::User.build_request_path(:_organization_id => "acme").should == "organizations/acme/utilisateurs"

          Foo::User.build_request_path(:id => "foo", :organization_id => "acme").should == "organizations/acme/utilisateurs/foo"
          Foo::User.build_request_path(:organization_id => "acme").should == "organizations/acme/utilisateurs"
        end

        it "builds paths with custom item path" do
          Foo::User.resource_path "/utilisateurs/:id"
          Foo::User.build_request_path(:id => "foo").should == "/utilisateurs/foo"
          Foo::User.build_request_path.should == "users"
        end

        it "builds paths with custom relative item path" do
          Foo::User.resource_path "utilisateurs/:id"
          Foo::User.build_request_path(:id => "foo").should == "utilisateurs/foo"
          Foo::User.build_request_path.should == "users"
        end

        it "raises exceptions when building a path without required custom variables" do
          Foo::User.collection_path "/organizations/:organization_id/utilisateurs"
          expect { Foo::User.build_request_path(:id => "foo") }.to raise_error(Her::Errors::PathError, "Missing :_organization_id parameter to build the request path. Path is `/organizations/:organization_id/utilisateurs/:id`. Parameters are `{:id=>\"foo\"}`.")
        end
      end
    end

    context "simple model with multiple words" do
      before do
        spawn_model "Foo::AdminUser"
      end

      describe "#build_request_path" do
        it "builds paths with defaults" do
          Foo::AdminUser.build_request_path(:id => "foo").should == "admin_users/foo"
          Foo::AdminUser.build_request_path.should == "admin_users"
        end

        it "builds paths with custom collection path" do
          Foo::AdminUser.collection_path "/users"
          Foo::AdminUser.build_request_path(:id => "foo").should == "/users/foo"
          Foo::AdminUser.build_request_path.should == "/users"
        end

        it "builds paths with custom relative collection path" do
          Foo::AdminUser.collection_path "users"
          Foo::AdminUser.build_request_path(:id => "foo").should == "users/foo"
          Foo::AdminUser.build_request_path.should == "users"
        end

        it "builds paths with custom collection path with multiple variables" do
          Foo::AdminUser.collection_path "/organizations/:organization_id/users"
          Foo::AdminUser.build_request_path(:id => "foo", :_organization_id => "acme").should == "/organizations/acme/users/foo"
          Foo::AdminUser.build_request_path(:_organization_id => "acme").should == "/organizations/acme/users"
        end

        it "builds paths with custom relative collection path with multiple variables" do
          Foo::AdminUser.collection_path "organizations/:organization_id/users"
          Foo::AdminUser.build_request_path(:id => "foo", :_organization_id => "acme").should == "organizations/acme/users/foo"
          Foo::AdminUser.build_request_path(:_organization_id => "acme").should == "organizations/acme/users"
        end

        it "builds paths with custom item path" do
          Foo::AdminUser.resource_path "/users/:id"
          Foo::AdminUser.build_request_path(:id => "foo").should == "/users/foo"
          Foo::AdminUser.build_request_path.should == "admin_users"
        end

        it "builds paths with custom relative item path" do
          Foo::AdminUser.resource_path "users/:id"
          Foo::AdminUser.build_request_path(:id => "foo").should == "users/foo"
          Foo::AdminUser.build_request_path.should == "admin_users"
        end

        it "raises exceptions when building a path without required custom variables" do
          Foo::AdminUser.collection_path "/organizations/:organization_id/users"
          expect { Foo::AdminUser.build_request_path(:id => "foo") }.to raise_error(Her::Errors::PathError, "Missing :_organization_id parameter to build the request path. Path is `/organizations/:organization_id/users/:id`. Parameters are `{:id=>\"foo\"}`.")
        end

        it "raises exceptions when building a relative path without required custom variables" do
          Foo::AdminUser.collection_path "organizations/:organization_id/users"
          expect { Foo::AdminUser.build_request_path(:id => "foo") }.to raise_error(Her::Errors::PathError, "Missing :_organization_id parameter to build the request path. Path is `organizations/:organization_id/users/:id`. Parameters are `{:id=>\"foo\"}`.")
        end
      end
    end

    context "children model" do
      before do
        Her::API.setup :url => "https://api.example.com" do |builder|
          builder.use Her::Middleware::FirstLevelParseJSON
          builder.use Faraday::Request::UrlEncoded
          builder.adapter :test do |stub|
            stub.get("/users/foo") { |env| [200, {}, { :id => 'foo' }.to_json] }
          end
        end

        spawn_model("Foo::Model") { include_root_in_json true }

        class User < Foo::Model; end
        @spawned_models << :User
      end

      it "builds path using the children model name" do
        User.find('foo').id.should == 'foo'
        User.find('foo').id.should == 'foo'
      end
    end

    context "nested model" do
      before do
        spawn_model "Foo::User"
      end

      describe "#build_request_path" do
        it "builds paths with defaults" do
          Foo::User.build_request_path(:id => "foo").should == "users/foo"
          Foo::User.build_request_path.should == "users"
        end
      end
    end

    context 'custom primary key' do
      before do
        spawn_model 'User' do
          primary_key 'UserId'
          resource_path 'users/:UserId'
        end

        spawn_model 'Customer' do
          primary_key :customer_id
          resource_path 'customers/:id'
        end
      end

      describe '#build_request_path' do
        it 'uses the correct primary key attribute' do
          User.build_request_path(:UserId => 'foo').should == 'users/foo'
          User.build_request_path(:id => 'foo').should == 'users'
        end

        it 'replaces :id with the appropriate primary key' do
          Customer.build_request_path(:customer_id => 'joe').should == 'customers/joe'
          Customer.build_request_path(:id => 'joe').should == 'customers'
        end
      end
    end
  end

  context "making subdomain HTTP requests" do
    before do
      Her::API.setup :url => "https://api.example.com/" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("organizations/2/users") { |env| [200, {}, [{ :id => 1, :fullname => "Tobias Fünke", :organization_id => 2 }, { :id => 2, :fullname => "Lindsay Fünke", :organization_id => 2 }].to_json] }
          stub.post("organizations/2/users") { |env| [200, {}, { :id => 1, :fullname => "Tobias Fünke", :organization_id => 2 }.to_json] }
          stub.put("organizations/2/users/1") { |env| [200, {}, { :id => 1, :fullname => "Lindsay Fünke", :organization_id => 2 }.to_json] }
          stub.get("organizations/2/users/1") { |env| [200, {}, { :id => 1, :fullname => "Tobias Fünke", :organization_id => 2, :active => true }.to_json] }
          stub.delete("organizations/2/users/1") { |env| [200, {}, { :id => 1, :fullname => "Lindsay Fünke", :organization_id => 2, :active => false }.to_json] }
        end
      end

      spawn_model "Foo::User" do
        collection_path "organizations/:organization_id/users"
      end
    end

    describe "fetching a resource" do
      it "maps a single resource to a Ruby object" do
        @user = Foo::User.find(1, :_organization_id => 2)
        @user.id.should == 1
        @user.fullname.should == "Tobias Fünke"
      end

      it "maps a single resource using a scope to a Ruby object" do
        Foo::User.scope :for_organization, lambda { |o| where(:organization_id => o) }
        @user = Foo::User.for_organization(2).find(1)
        @user.id.should == 1
        @user.fullname.should == "Tobias Fünke"
      end
    end

    describe "fetching a collection" do
      it "maps a collection of resources to an array of Ruby objects" do
        @users = Foo::User.where(:_organization_id => 2).all
        @users.length.should == 2
        @users.first.fullname.should == "Tobias Fünke"
      end
    end

    describe "handling new resource" do
      it "handles new resource" do
        @new_user = Foo::User.new(:fullname => "Tobias Fünke", :organization_id => 2)
        @new_user.new?.should be_true

        @existing_user = Foo::User.find(1, :_organization_id => 2)
        @existing_user.new?.should be_false
      end
    end

    describe "creating resources" do
      it "handle one-line resource creation" do
        @user = Foo::User.create(:fullname => "Tobias Fünke", :organization_id => 2)
        @user.id.should == 1
        @user.fullname.should == "Tobias Fünke"
      end

      it "handle resource creation through Model.new + #save" do
        @user = Foo::User.new(:fullname => "Tobias Fünke", :organization_id => 2)
        @user.save
        @user.fullname.should == "Tobias Fünke"
      end
    end

    context "updating resources" do
      it "handle resource data update without saving it" do
        @user = Foo::User.find(1, :_organization_id => 2)
        @user.fullname.should == "Tobias Fünke"
        @user.fullname = "Kittie Sanchez"
        @user.fullname.should == "Kittie Sanchez"
      end

      it "handle resource update through the .update class method" do
        @user = Foo::User.save_existing(1, { :fullname => "Lindsay Fünke", :organization_id => 2 })
        @user.fullname.should == "Lindsay Fünke"
      end

      it "handle resource update through #save on an existing resource" do
        @user = Foo::User.find(1, :_organization_id => 2)
        @user.fullname = "Lindsay Fünke"
        @user.save
        @user.fullname.should == "Lindsay Fünke"
      end
    end

    context "deleting resources" do
      it "handle resource deletion through the .destroy class method" do
        @user = Foo::User.destroy_existing(1, :_organization_id => 2)
        @user.active.should be_false
      end

      it "handle resource deletion through #destroy on an existing resource" do
        @user = Foo::User.find(1, :_organization_id => 2)
        @user.destroy
        @user.active.should be_false
      end
    end
  end

  context "making path HTTP requests" do
    before do
      Her::API.setup :url => "https://example.com/api/" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/api/organizations/2/users") { |env| [200, {}, [{ :id => 1, :fullname => "Tobias Fünke", :organization_id => 2 }, { :id => 2, :fullname => "Lindsay Fünke", :organization_id => 2 }].to_json] }
          stub.get("/api/organizations/2/users/1") { |env| [200, {}, { :id => 1, :fullname => "Tobias Fünke", :organization_id => 2, :active => true }.to_json] }
        end
      end

      spawn_model "Foo::User" do
        collection_path "organizations/:organization_id/users"
      end
    end

    describe "fetching a resource" do
      it "maps a single resource to a Ruby object" do
        @user = Foo::User.find(1, :_organization_id => 2)
        @user.id.should == 1
        @user.fullname.should == "Tobias Fünke"
      end
    end

    describe "fetching a collection" do
      it "maps a collection of resources to an array of Ruby objects" do
        @users = Foo::User.where(:_organization_id => 2).all
        @users.length.should == 2
        @users.first.fullname.should == "Tobias Fünke"
      end
    end

    describe "fetching a resource with absolute path" do
      it "maps a single resource to a Ruby object" do
        Foo::User.resource_path '/api/' + Foo::User.resource_path
        @user = Foo::User.find(1, :_organization_id => 2)
        @user.id.should == 1
        @user.fullname.should == "Tobias Fünke"
      end
    end

    describe "fetching a collection with absolute path" do
      it "maps a collection of resources to an array of Ruby objects" do
        Foo::User.collection_path '/api/' + Foo::User.collection_path
        @users = Foo::User.where(:_organization_id => 2).all
        @users.length.should == 2
        @users.first.fullname.should == "Tobias Fünke"
      end
    end
  end
end
