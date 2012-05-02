# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe Her::Model::ORM do
  context "mapping data to Ruby objects" do
    before do # {{{
      api = Her::API.new
      api.setup :base_uri => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.use Faraday::Adapter::NetHttp
      end

      FakeWeb.register_uri(:get, "https://api.example.com/users/1", :body => { :id => 1, :name => "Tobias Fünke" }.to_json)
      FakeWeb.register_uri(:get, "https://api.example.com/users", :body => [{ :id => 1, :name => "Tobias Fünke" }, { :id => 2, :name => "Lindsay Fünke" }].to_json)
      FakeWeb.register_uri(:get, "https://api.example.com/admin_users", :body => [{ :id => 1, :name => "Tobias Fünke" }, { :id => 2, :name => "Lindsay Fünke" }].to_json)

      spawn_model :User do
        uses_api api
      end

      spawn_model :AdminUser do
        uses_api api
      end
    end # }}}

    it "maps a single resource to a Ruby object" do # {{{
      @user = User.find(1)
      @user.id.should == 1
      @user.name.should == "Tobias Fünke"
    end # }}}

    it "maps a collection of resources to an array of Ruby objects" do # {{{
      @users = User.all
      @users.length.should == 2
      @users.first.name.should == "Tobias Fünke"

      @users = AdminUser.all
      @users.length.should == 2
      @users.first.name.should == "Tobias Fünke"
    end # }}}

    it "handles new resource" do # {{{
      @new_user = User.new(:fullname => "Tobias Fünke")
      @new_user.new?.should be_true

      @existing_user = User.find(1)
      @existing_user.new?.should be_false
    end # }}}
  end

  context "creating resources" do
    before do # {{{
      Her::API.setup :base_uri => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.use Faraday::Adapter::NetHttp
      end

      FakeWeb.register_uri(:post, "https://api.example.com/users", :body => { :id => 1, :fullname => "Tobias Fünke" }.to_json)

      spawn_model :User
    end # }}}

    it "handle one-line resource creation" do # {{{
      @user = User.create(:fullname => "Tobias Fünke")
      @user.id.should == 1
      @user.fullname.should == "Tobias Fünke"
    end # }}}

    it "handle resource creation through Model.new + #save" do # {{{
      @user = User.new(:fullname => "Tobias Fünke")
      @user.save
      @user.fullname.should == "Tobias Fünke"
    end # }}}
  end

  context "updating resources" do
    before do # {{{
      @api = Her::API.new
      @api.setup :base_uri => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.use Faraday::Adapter::NetHttp
      end

      FakeWeb.register_uri(:get, "https://api.example.com/users/1", :body => { :id => 1, :fullname => "Tobias Fünke" }.to_json)
      FakeWeb.register_uri(:put, "https://api.example.com/users/1", :body => { :id => 1, :fullname => "Lindsay Fünke" }.to_json)

      spawn_model :User
    end # }}}

    it "handle resource data update without saving it" do # {{{
      @user = User.find(1)
      @user.fullname.should == "Tobias Fünke"
      @user.fullname = "Kittie Sanchez"
      @user.fullname.should == "Kittie Sanchez"
    end # }}}

    it "handle resource update through the .update class method" do # {{{
      @user = User.save_existing(1, { :fullname => "Lindsay Fünke" })
      @user.fullname.should == "Lindsay Fünke"
    end # }}}

    it "handle resource update through #save on an existing resource" do # {{{
      @user = User.find(1)
      @user.fullname = "Lindsay Fünke"
      @user.save
      @user.fullname.should == "Lindsay Fünke"
    end # }}}
  end

  context "deleting resources" do
    before do # {{{
      @api = Her::API.new
      @api.setup :base_uri => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.use Faraday::Adapter::NetHttp
      end

      FakeWeb.register_uri(:get, "https://api.example.com/users/1", :body => { :id => 1, :fullname => "Tobias Fünke", :active => true }.to_json)
      FakeWeb.register_uri(:delete, "https://api.example.com/users/1", :body => { :id => 1, :fullname => "Lindsay Fünke", :active => false }.to_json)

      spawn_model :User
    end # }}}

    it "handle resource deletion through the .destroy class method" do # {{{
      @user = User.destroy_existing(1)
      @user.active.should be_false
    end # }}}

    it "handle resource deletion through #destroy on an existing resource" do # {{{
      @user = User.find(1)
      @user.destroy
      @user.active.should be_false
    end # }}}
  end
end
