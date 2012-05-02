# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe Her::Model::Relationships do
  context "setting relationships" do
    before do # {{{
      spawn_model :User
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

    it "handles a single 'has_one' relationship" do # {{{
      User.has_one :category
      User.relationships[:has_one].should == [{ :name => :category }]
    end # }}}

    it "handles multiples 'has_one' relationship" do # {{{
      User.has_one :category
      User.has_one :role
      User.relationships[:has_one].should == [{ :name => :category }, { :name => :role }]
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
      Her::API.setup :base_uri => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.use Faraday::Adapter::NetHttp
      end

      FakeWeb.register_uri(:get, "https://api.example.com/users/1", :body => { :id => 1, :name => "Tobias Fünke", :comments => [{ :id => 2, :body => "Tobias, you blow hard!" }, { :id => 3, :body => "I wouldn't mind kissing that man between the cheeks, so to speak" }], :role => { :id => 1, :body => "Admin" }, :organization => { :id => 1, :name => "Bluth Company" }, :organization_id => 1 }.to_json)
      FakeWeb.register_uri(:get, "https://api.example.com/users/2", :body => { :id => 2, :name => "Lindsay Fünke", :organization_id => 1 }.to_json)
      FakeWeb.register_uri(:get, "https://api.example.com/users/2/comments", :body => [{ :id => 4, :body => "They're having a FIRESALE?" }, { :id => 5, :body => "Is this the tiny town from Footloose?" }].to_json)
      FakeWeb.register_uri(:get, "https://api.example.com/users/2/role", :body => { :id => 2, :body => "User" }.to_json)
      FakeWeb.register_uri(:get, "https://api.example.com/organizations/1", :body => { :id => 1, :name => "Bluth Company" }.to_json)

      spawn_model :User do
        has_many :comments
        has_one :role
        belongs_to :organization
      end

      spawn_model :Organization
      spawn_model :Comment
      spawn_model :Role


      @user_with_included_data = User.find(1)
      @user_without_included_data = User.find(2)
    end # }}}

    it "maps an array of included data through has_many" do # {{{
      @user_with_included_data.comments.length.should == 2
      @user_with_included_data.comments.first.id.should == 2
      @user_with_included_data.comments.first.body.should == "Tobias, you blow hard!"
    end # }}}

    it "fetches data that was not included through has_many" do # {{{
      @user_without_included_data.comments.length.should == 2
      @user_without_included_data.comments.first.id.should == 4
      @user_without_included_data.comments.first.body.should == "They're having a FIRESALE?"
    end # }}}

    it "maps an array of included data through has_one" do # {{{
      @user_with_included_data.role.id.should == 1
      @user_with_included_data.role.body.should == "Admin"
    end # }}}

    it "fetches data that was not included through has_one" do # {{{
      @user_without_included_data.role.id.should == 2
      @user_without_included_data.role.body.should == "User"
    end # }}}

    it "maps an array of included data through belongs_to" do # {{{
      @user_with_included_data.organization.id.should == 1
      @user_with_included_data.organization.name.should == "Bluth Company"
    end # }}}

    it "fetches data that was not included through belongs_to" do # {{{
      @user_without_included_data.organization.id.should == 1
      @user_without_included_data.organization.name.should == "Bluth Company"
    end # }}}
  end
end
