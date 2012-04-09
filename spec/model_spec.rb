# encoding: utf-8
require File.join(File.dirname(__FILE__), "spec_helper.rb")

describe Her::Model do
  describe Her::Model::ORM do
    context "mapping data to Ruby objects" do # {{{
      before do # {{{
        @api = Her::API.new
        @api.setup :base_uri => "https://api.example.com"
        FakeWeb.register_uri(:get, "https://api.example.com/users/1", :body => { :data => { :id => 1, :name => "Tobias Fünke" } }.to_json)
        FakeWeb.register_uri(:get, "https://api.example.com/users", :body => { :data => [{ :id => 1, :name => "Tobias Fünke" }, { :id => 2, :name => "Lindsay Fünke" }] }.to_json)

        User = Class.new
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
    end # }}}
  end

  describe Her::Model::Relationships do
    context "setting associations" do # {{{
      before do # {{{
        User = Class.new # FIXME There has to be a better way to reset the class…
        class User
          include Her::Model
        end
      end # }}}

      it "handles a single 'has_many' association" do # {{{
        User.has_many :comments
        User.relationships[:has_many].should == [{ :name => :comments }]
      end # }}}

      it "handles multiples 'has_many' associations" do # {{{
        User.has_many :comments
        User.has_many :posts
        User.relationships[:has_many].should == [{ :name => :comments }, { :name => :posts }]
      end # }}}

      it "handles a single belongs_to association" do # {{{
        User.belongs_to :organization
        User.relationships[:belongs_to].should == [{ :name => :organization }]
      end # }}}

      it "handles multiples 'belongs_to' associations" do # {{{
        User.belongs_to :organization
        User.belongs_to :family
        User.relationships[:belongs_to].should == [{ :name => :organization }, { :name => :family }]
      end # }}}
    end # }}}
  end
end
