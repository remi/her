# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe Her::Model::Paths do
  #--------------------------------------------------------------------------------------------
  # Her::Model::Paths#build_request_path
  #--------------------------------------------------------------------------------------------
  describe :build_request_path do
    subject { Foo::User.build_request_path(arguments) }

    context "with default collection_path" do
      before { spawn_model 'Foo::User' }

      context "with :id parameter" do
        let(:arguments) { { :id => "foo" } }
        it { should == "users/foo" }
      end

      context "with nil :id parameter" do
        let(:arguments) { { :id => nil } }
        it { should == "users" }
      end

      context "with extra parameters" do
        let(:arguments) { { :foo => "bar" } }
        # Extra parameters are taken into account but are not part of the path
        it { should == "users" }
      end

      context "without parameters" do
        let(:arguments) { {} }
        it { should == "users" }
      end
    end

    context "with custom collection_path" do
      before do
        spawn_model('Foo::User') { collection_path 'utilisateurs' }
      end

      context "with :id parameter" do
        let(:arguments) { { :id => "foo" } }
        it { should == "utilisateurs/foo" }
      end

      context "with nil :id parameter" do
        let(:arguments) { { :id => nil } }
        it { should == "utilisateurs" }
      end

      context "without parameters" do
        let(:arguments) { {} }
        it { should == "utilisateurs" }
      end
    end

    context "with custom complex collection path" do
      before do
        spawn_model('Foo::User') { collection_path '/organizations/:organization_id/users' }
      end

      context "with :id parameter" do
        let(:arguments) { { :id => "foo", :_organization_id => "acme" } }
        it { should == "/organizations/acme/users/foo" }
      end

      context "without :id parameter" do
        let(:arguments) { { :_organization_id => "acme" } }
        it { should == "/organizations/acme/users" }
      end

      context "without :_organization_id parameter" do
        subject { nil }
        specify do
          expect {
            Foo::User.build_request_path(:id => "foo")
          }.to raise_error(Her::Errors::PathError, "Missing :_organization_id parameter to build the request path. Path is `/organizations/:organization_id/users/:id`. Parameters are `{:id=>\"foo\"}`.")
        end
      end
    end

    context "with custom resource path" do
      before do
        spawn_model('Foo::User') { resource_path '/organizations/:organization_id/users/:id' }
      end

      context "with :_organization_id and :id parameter" do
        let(:arguments) { { :id => "foo", :_organization_id => "bar" } }
        it { should == "/organizations/bar/users/foo" }
      end

      context "with only :id parameter" do
        subject { nil }
        specify do
          expect {
            Foo::User.build_request_path(:id => "foo")
          }.to raise_error(Her::Errors::PathError, "Missing :_organization_id parameter to build the request path. Path is `/organizations/:organization_id/users/:id`. Parameters are `{:id=>\"foo\"}`.")
        end
      end
    end
  end
end
