# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe Her::Model::Paths do
  context "building request paths" do
    context "simple model" do
      before do # {{{
        spawn_model :User
      end # }}}

      describe "#build_request_path" do
        it "builds paths with defaults" do # {{{
          User.build_request_path(:id => "foo").should == "/users/foo"
          User.build_request_path.should == "/users"
        end # }}}

        it "builds paths with custom collection path" do # {{{
          User.collection_path "/utilisateurs"
          User.build_request_path(:id => "foo").should == "/utilisateurs/foo"
          User.build_request_path.should == "/utilisateurs"
        end # }}}

        it "builds paths with custom collection path with multiple variables" do # {{{
          User.collection_path "/organizations/:organization_id/utilisateurs"
          User.build_request_path(:id => "foo", :_organization_id => "acme").should == "/organizations/acme/utilisateurs/foo"
          User.build_request_path(:_organization_id => "acme").should == "/organizations/acme/utilisateurs"
        end # }}}

        it "builds paths with custom item path" do # {{{
          User.resource_path "/utilisateurs/:id"
          User.build_request_path(:id => "foo").should == "/utilisateurs/foo"
          User.build_request_path.should == "/users"
        end # }}}

        it "raises exceptions when building a path without required custom variables" do # {{{
          User.collection_path "/organizations/:organization_id/utilisateurs"
          expect { User.build_request_path(:id => "foo") }.should raise_error(Her::Errors::PathError)
        end # }}}
      end
    end

    context "simple model with multiple words" do
      before do # {{{
        spawn_model :AdminUser
      end # }}}

      describe "#build_request_path" do
        it "builds paths with defaults" do # {{{
          AdminUser.build_request_path(:id => "foo").should == "/admin_users/foo"
          AdminUser.build_request_path.should == "/admin_users"
        end # }}}

        it "builds paths with custom collection path" do # {{{
          AdminUser.collection_path "/users"
          AdminUser.build_request_path(:id => "foo").should == "/users/foo"
          AdminUser.build_request_path.should == "/users"
        end # }}}

        it "builds paths with custom collection path with multiple variables" do # {{{
          AdminUser.collection_path "/organizations/:organization_id/users"
          AdminUser.build_request_path(:id => "foo", :_organization_id => "acme").should == "/organizations/acme/users/foo"
          AdminUser.build_request_path(:_organization_id => "acme").should == "/organizations/acme/users"
        end # }}}

        it "builds paths with custom item path" do # {{{
          AdminUser.resource_path "/users/:id"
          AdminUser.build_request_path(:id => "foo").should == "/users/foo"
          AdminUser.build_request_path.should == "/admin_users"
        end # }}}

        it "raises exceptions when building a path without required custom variables" do # {{{
          AdminUser.collection_path "/organizations/:organization_id/users"
          expect { AdminUser.build_request_path(:id => "foo") }.should raise_error(Her::Errors::PathError)
        end # }}}
      end
    end

    context "nested model" do
      before do # {{{
        spawn_model "Base::User"
      end # }}}

      describe "#build_request_path" do
        it "builds paths with defaults" do # {{{
          Base::User.build_request_path(:id => "foo").should == "/users/foo"
          Base::User.build_request_path.should == "/users"
        end # }}}
      end
    end
  end

  context "making HTTP requests" do
    before do # {{{
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/organizations/2/users") { |env| [200, {}, [{ :id => 1, :fullname => "Tobias Fünke", :organization_id => 2 }, { :id => 2, :fullname => "Lindsay Fünke", :organization_id => 2 }].to_json] }
          stub.post("/organizations/2/users") { |env| [200, {}, { :id => 1, :fullname => "Tobias Fünke", :organization_id => 2 }.to_json] }
          stub.put("/organizations/2/users/1") { |env| [200, {}, { :id => 1, :fullname => "Lindsay Fünke", :organization_id => 2 }.to_json] }
          stub.get("/organizations/2/users/1") { |env| [200, {}, { :id => 1, :fullname => "Tobias Fünke", :organization_id => 2, :active => true }.to_json] }
          stub.delete("/organizations/2/users/1") { |env| [200, {}, { :id => 1, :fullname => "Lindsay Fünke", :organization_id => 2, :active => false }.to_json] }
        end
      end

      spawn_model :User do
        collection_path "/organizations/:organization_id/users"
      end
    end # }}}

    describe "fetching a resource" do
      it "maps a single resource to a Ruby object" do # {{{
        @user = User.find(1, :_organization_id => 2)
        @user.id.should == 1
        @user.fullname.should == "Tobias Fünke"
      end # }}}
    end

    describe "fetching a collection" do
      it "maps a collection of resources to an array of Ruby objects" do # {{{
        @users = User.all(:_organization_id => 2)
        @users.length.should == 2
        @users.first.fullname.should == "Tobias Fünke"
      end # }}}
    end

    describe "handling new resource" do
      it "handles new resource" do # {{{
        @new_user = User.new(:fullname => "Tobias Fünke", :organization_id => 2)
        @new_user.new?.should be_true

        @existing_user = User.find(1, :_organization_id => 2)
        @existing_user.new?.should be_false
      end # }}}
    end

    describe "creating resources" do
      it "handle one-line resource creation" do # {{{
        @user = User.create(:fullname => "Tobias Fünke", :organization_id => 2)
        @user.id.should == 1
        @user.fullname.should == "Tobias Fünke"
      end # }}}

      it "handle resource creation through Model.new + #save" do # {{{
        @user = User.new(:fullname => "Tobias Fünke", :organization_id => 2)
        @user.save
        @user.fullname.should == "Tobias Fünke"
      end # }}}
    end

    context "updating resources" do
      it "handle resource data update without saving it" do # {{{
        @user = User.find(1, :_organization_id => 2)
        @user.fullname.should == "Tobias Fünke"
        @user.fullname = "Kittie Sanchez"
        @user.fullname.should == "Kittie Sanchez"
      end # }}}

      it "handle resource update through the .update class method" do # {{{
        @user = User.save_existing(1, { :fullname => "Lindsay Fünke", :organization_id => 2 })
        @user.fullname.should == "Lindsay Fünke"
      end # }}}

      it "handle resource update through #save on an existing resource" do # {{{
        @user = User.find(1, :_organization_id => 2)
        @user.fullname = "Lindsay Fünke"
        @user.save
        @user.fullname.should == "Lindsay Fünke"
      end # }}}
    end

    context "deleting resources" do
      it "handle resource deletion through the .destroy class method" do # {{{
        @user = User.destroy_existing(1, :_organization_id => 2)
        @user.active.should be_false
      end # }}}

      it "handle resource deletion through #destroy on an existing resource" do # {{{
        @user = User.find(1, :_organization_id => 2)
        @user.destroy
        @user.active.should be_false
      end # }}}
    end
  end
end
