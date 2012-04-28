# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe Her::Model::Paths do
  context "building request paths" do
    before do # {{{
      spawn_model :User
    end # }}}

    describe "#build_request_path" do
      it "builds paths with defaults" do # {{{
        User.build_request_path(id: "foo").should == "/users/foo"
        User.build_request_path.should == "/users"
      end # }}}

      it "builds paths with custom collection path" do # {{{
        User.collection_path "/utilisateurs"
        User.build_request_path(id: "foo").should == "/utilisateurs/foo"
        User.build_request_path.should == "/utilisateurs"
      end # }}}

      it "builds paths with custom collection path with multiple variables" do # {{{
        User.collection_path "/organizations/:organization_id/utilisateurs"
        User.build_request_path(:id => "foo", :organization_id => "acme").should == "/organizations/acme/utilisateurs/foo"
        User.build_request_path(:organization_id => "acme").should == "/organizations/acme/utilisateurs"
      end # }}}

      it "builds paths with custom item path" do # {{{
        User.resource_path "/utilisateurs/:id"
        User.build_request_path(id: "foo").should == "/utilisateurs/foo"
        User.build_request_path.should == "/users"
      end # }}}

      it "raises exceptions when building a path without required custom variables" do # {{{
        User.collection_path "/organizations/:organization_id/utilisateurs"
        expect { User.build_request_path(:id => "foo") }.should raise_error(Her::Errors::PathError)
      end # }}}
    end
  end
end
