# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe Her::Model::Relation do
  describe :where do
    before do
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.adapter :test do |stub|
          stub.get("/users") { |env| ok! [{ :id => 1, :fullname => "Tobias Fünke" }, { :id => 2, :fullname => "Lindsay Fünke" }] }
          stub.get("/users?admin=1") { |env| ok! [{ :id => 1, :fullname => "Tobias Fünke" }] }
        end
      end

      spawn_model "Foo::User"
    end

    it "doesn't fetch the data immediatly" do
      Her::Model::Relation.any_instance.should_receive(:fetch).never
      @users = Foo::User.where(:admin => 1)
    end

    it "fetches the data and passes query parameters" do
      Her::Model::Relation.any_instance.should_receive(:fetch).once.and_call_original
      @users = Foo::User.where(:admin => 1)
      @users.length.should == 2
    end
  end

  describe :create do
    before do
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.post("/users") { |env| ok! :id => 1, :fullname => params(env)[:fullname], :email => params(env)[:email] }
        end
      end

      spawn_model "Foo::User"
    end

    context "with a single where call" do
      it "creates a resource and passes the query parameters" do
        @user = Foo::User.where(:fullname => "Tobias Fünke", :email => "tobias@bluth.com").create
        @user.id.should == 1
        @user.fullname.should == "Tobias Fünke"
        @user.email.should == "tobias@bluth.com"
      end
    end

    context "with multiple where calls" do
      it "creates a resource and passes the query parameters" do
        @user = Foo::User.where(:fullname => "Tobias Fünke").create(:email => "tobias@bluth.com")
        @user.id.should == 1
        @user.fullname.should == "Tobias Fünke"
        @user.email.should == "tobias@bluth.com"
      end
    end
  end

  describe "#page and #per_page" do
    before do
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.adapter :test do |stub|
          stub.get("/users?page=2&per_page=1") { |env| ok! [{ :id => 2, :fullname => "Lindsay Fünke" }] }
        end
      end

      spawn_model "Foo::User"
    end

    it "passes the pagination parameters" do
      @user = Foo::User.page(2).per_page(1).first
      @user.id.should == 2
    end
  end

  describe :build do
    before { spawn_model "Foo::User" }

    it "handles new resource with build" do
      @new_user = Foo::User.where(:fullname => "Tobias Fünke").build
      @new_user.new?.should be_true
      @new_user.fullname.should == "Tobias Fünke"
    end
  end
end
