# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe Her::Model::ORM do
  context "mapping data to Ruby objects" do
    before do # {{{
      @api = Her::API.new
      @api.setup :base_uri => "https://api.example.com"
      FakeWeb.register_uri(:get, "https://api.example.com/users/1", :body => { :data => { :id => 1, :name => "Tobias Fünke" } }.to_json)
      FakeWeb.register_uri(:get, "https://api.example.com/users", :body => { :data => [{ :id => 1, :name => "Tobias Fünke" }, { :id => 2, :name => "Lindsay Fünke" }] }.to_json)

      Object.instance_eval { remove_const :User } if Object.const_defined?(:User)
      class User
        include Her::Model
      end
      User.uses_api @api
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
    end # }}}
  end

  context "creating resources" do
    before do # {{{
      Her::API.setup :base_uri => "https://api.example.com"
      FakeWeb.register_uri(:post, "https://api.example.com/users", :body => { :data => { :id => 1, :fullname => "Tobias Fünke" } }.to_json)

      Object.instance_eval { remove_const :User } if Object.const_defined?(:User)
      class User
        include Her::Model
      end
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
      @api.setup :base_uri => "https://api.example.com"
      FakeWeb.register_uri(:get, "https://api.example.com/users/1", :body => { :data => { :id => 1, :fullname => "Tobias Fünke" } }.to_json)
      FakeWeb.register_uri(:put, "https://api.example.com/users/1", :body => { :data => { :id => 1, :fullname => "Lindsay Fünke" } }.to_json)

      Object.instance_eval { remove_const :User } if Object.const_defined?(:User)
      class User
        include Her::Model
      end
    end # }}}

    it "handle resource data update without saving it" do # {{{
      @user = User.find(1)
      @user.fullname.should == "Tobias Fünke"
      @user.fullname = "Kittie Sanchez"
      @user.fullname.should == "Kittie Sanchez"
    end # }}}

    it "handle resource update through the .update class method" do # {{{
      @user = User.update(1, { :fullname => "Lindsay Fünke" })
      @user.fullname.should == "Lindsay Fünke"
    end # }}}

    it "handle resource update through #save on an existing resource" do # {{{
      @user = User.find(1)
      @user.fullname = "Lindsay Fünke"
      @user.save
      @user.fullname.should == "Lindsay Fünke"
    end # }}}
  end
end
