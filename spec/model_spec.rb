# encoding: utf-8
require File.join(File.dirname(__FILE__), "spec_helper.rb")

describe Her::Model do
  describe Her::Model::HTTP do
    context "binding a model with an API" do
      it "binds a model to an instance of Her::API" do # {{{
        @api = Her::API.new
        @api.setup :base_uri => "https://api.example.com"

        Object.instance_eval { remove_const :User } if Object.const_defined?(:User)
        class User
          include Her::Model
        end
        User.uses_api @api

        User.class_eval do
          @her_api.should_not == nil
          @her_api.base_uri.should == "https://api.example.com"
        end
      end # }}}

      it "binds a model directly to Her::API" do # {{{
        Her::API.setup :base_uri => "https://api.example.com"

        Object.instance_eval { remove_const :User } if Object.const_defined?(:User)
        class User
          include Her::Model
        end

        User.class_eval do
          @her_api.should_not == nil
          @her_api.base_uri.should == "https://api.example.com"
        end
      end # }}}

      it "binds two models to two different instances of Her::API" do # {{{
        @api1 = Her::API.new
        @api1.setup :base_uri => "https://api1.example.com"

        Object.instance_eval { remove_const :User } if Object.const_defined?(:User)
        class User; include Her::Model; end
        User.uses_api @api1

        User.class_eval do
          @her_api.base_uri.should == "https://api1.example.com"
        end

        @api2 = Her::API.new
        @api2.setup :base_uri => "https://api2.example.com"

        Object.instance_eval { remove_const :Comment } if Object.const_defined?(:Comment)
        class Comment; include Her::Model; end
        Comment.uses_api @api2

        Comment.class_eval do
          @her_api.base_uri.should == "https://api2.example.com"
        end
      end # }}}

      it "binds one model to Her::API and another one to an instance of Her::API" do # {{{
        Her::API.setup :base_uri => "https://api1.example.com"
        Object.instance_eval { remove_const :User } if Object.const_defined?(:User)
        class User; include Her::Model; end

        User.class_eval do
          @her_api.base_uri.should == "https://api1.example.com"
        end

        @api = Her::API.new
        @api.setup :base_uri => "https://api2.example.com"

        Object.instance_eval { remove_const :Comment } if Object.const_defined?(:Comment)
        class Comment; include Her::Model; end
        Comment.uses_api @api

        Comment.class_eval do
          @her_api.base_uri.should == "https://api2.example.com"
        end
      end # }}}
    end

    context "making HTTP requests" do
      before do # {{{
        @api = Her::API.new
        @api.setup :base_uri => "https://api.example.com"
        FakeWeb.register_uri(:get, "https://api.example.com/users", :body => { :data => [{ :id => 1 }] }.to_json)
        FakeWeb.register_uri(:get, "https://api.example.com/users?page=2", :body => { :data => [{ :id => 2 }] }.to_json)
        FakeWeb.register_uri(:get, "https://api.example.com/users/popular", :body => { :data => [{ :id => 1 }, { :id => 2 }] }.to_json)
        FakeWeb.register_uri(:get, "https://api.example.com/users/1", :body => { :data => { :id => 1 } }.to_json)
        FakeWeb.register_uri(:post, "https://api.example.com/users", :body => { :data => [{ :id => 3 }] }.to_json)
        FakeWeb.register_uri(:put, "https://api.example.com/users/4", :body => { :data => [{ :id => 4 }] }.to_json)
        FakeWeb.register_uri(:patch, "https://api.example.com/users/6", :body => { :data => [{ :id => 6 }] }.to_json)
        FakeWeb.register_uri(:delete, "https://api.example.com/users/5", :body => { :data => [{ :id => 5 }] }.to_json)

        Object.instance_eval { remove_const :User } if Object.const_defined?(:User)
        class User
          include Her::Model
        end
        User.uses_api @api
      end # }}}

      it "handle raw GET" do # {{{
        User.get_raw("/users") do |parsed_data|
          parsed_data[:data].should == [{ :id => 1 }]
        end
      end # }}}

      it "handle raw POST" do # {{{
        User.post_raw("/users") do |parsed_data|
          parsed_data[:data].should == [{ :id => 3 }]
        end
      end # }}}

      it "handle raw PUT" do # {{{
        User.put_raw("/users/4") do |parsed_data|
          parsed_data[:data].should == [{ :id => 4 }]
        end
      end # }}}

      it "handle raw PATCH" do # {{{
        User.patch_raw("/users/6") do |parsed_data|
          parsed_data[:data].should == [{ :id => 6 }]
        end
      end # }}}

      it "handle raw DELETE" do # {{{
        User.delete_raw("/users/5") do |parsed_data|
          parsed_data[:data].should == [{ :id => 5 }]
        end
      end # }}}

      it "handle querystring parameters" do # {{{
        User.get_raw("/users", :page => 2) do |parsed_data|
          parsed_data[:data].should == [{ :id => 2 }]
        end
      end # }}}

      it "handle GET collection" do # {{{
        @users = User.get_collection("/users/popular")
        @users.length.should == 2
        @users.first.id.should == 1
      end # }}}

      it "handle GET resource" do # {{{
        @user = User.get_resource("/users/1")
        @user.id.should == 1
      end # }}}
    end
  end

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
    end
  end

  describe Her::Model::Relationships do
    context "setting relationships" do
      before do # {{{
        Object.instance_eval { remove_const :User } if Object.const_defined?(:User)
        class User
          include Her::Model
        end
      end # }}}

      it "handles a single 'has_many' relationship" do # {{{
        User.has_many :comments
        User.relationships[:has_many].should == [{ :name => :comments }]
      end # }}}

      it "handles multiples 'has_many' relationship" do # {{{
        User.has_many :comments
        User.has_many :posts
        User.relationships[:has_many].should == [{ :name => :comments }, { :name => :posts }]
      end # }}}

      it "handles a single belongs_to relationship" do # {{{
        User.belongs_to :organization
        User.relationships[:belongs_to].should == [{ :name => :organization }]
      end # }}}

      it "handles multiples 'belongs_to' relationship" do # {{{
        User.belongs_to :organization
        User.belongs_to :family
        User.relationships[:belongs_to].should == [{ :name => :organization }, { :name => :family }]
      end # }}}
    end

    context "handling relationships" do
      before do # {{{
        Her::API.setup :base_uri => "https://api.example.com"
        FakeWeb.register_uri(:get, "https://api.example.com/users/1", :body => { :data => { :id => 1, :name => "Tobias Fünke", :comments => [{ :id => 2, :body => "Tobias, you blow hard!" }, { :id => 3, :body => "I wouldn't mind kissing that man between the cheeks, so to speak" }] } }.to_json)
        FakeWeb.register_uri(:get, "https://api.example.com/users/2", :body => { :data => { :id => 2, :name => "Lindsay Fünke" } }.to_json)
        FakeWeb.register_uri(:get, "https://api.example.com/users/2/comments", :body => { :data => [{ :id => 4, :body => "They're having a FIRESALE?" }, { :id => 5, :body => "Is this the tiny town from Footloose?" }] }.to_json)

        Object.instance_eval { remove_const :User } if Object.const_defined?(:User)
        class User
          include Her::Model
          has_many :comments
        end

        Object.instance_eval { remove_const :Comment } if Object.const_defined?(:Comment)
        class Comment
          include Her::Model
        end
      end # }}}

      it "maps an array of included data" do # {{{
        @user = User.find(1)
        @user.comments.length.should == 2
        @user.comments.first.id.should == 2
        @user.comments.first.body.should == "Tobias, you blow hard!"
      end # }}}

      it "fetches data that was not included" do # {{{
        @user = User.find(2)
        @user.comments.length.should == 2
        @user.comments.first.id.should == 4
        @user.comments.first.body.should == "They're having a FIRESALE?"
      end # }}}
    end
  end
end
