# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe Her::Model::Relationships do
  context "setting relationships without details" do
    before do # {{{
      spawn_model "Foo::User"
    end # }}}

    it "handles a single 'has_many' relationship" do # {{{
      Foo::User.has_many :comments
      Foo::User.relationships[:has_many].should == [{ :name => :comments, :class_name => "Comment", :path => "/comments" }]
    end # }}}

    it "handles multiples 'has_many' relationship" do # {{{
      Foo::User.has_many :comments
      Foo::User.has_many :posts
      Foo::User.relationships[:has_many].should == [{ :name => :comments, :class_name => "Comment", :path => "/comments" }, { :name => :posts, :class_name => "Post", :path => "/posts" }]
    end # }}}

    it "handles a single 'has_one' relationship" do # {{{
      Foo::User.has_one :category
      Foo::User.relationships[:has_one].should == [{ :name => :category, :class_name => "Category", :path => "/category" }]
    end # }}}

    it "handles multiples 'has_one' relationship" do # {{{
      Foo::User.has_one :category
      Foo::User.has_one :role
      Foo::User.relationships[:has_one].should == [{ :name => :category, :class_name => "Category", :path => "/category" }, { :name => :role, :class_name => "Role", :path => "/role" }]
    end # }}}

    it "handles a single belongs_to relationship" do # {{{
      Foo::User.belongs_to :organization
      Foo::User.relationships[:belongs_to].should == [{ :name => :organization, :class_name => "Organization", :foreign_key => "organization_id", :path => "/organizations/:id" }]
    end # }}}

    it "handles multiples 'belongs_to' relationship" do # {{{
      Foo::User.belongs_to :organization
      Foo::User.belongs_to :family
      Foo::User.relationships[:belongs_to].should == [{ :name => :organization, :class_name => "Organization", :foreign_key => "organization_id", :path => "/organizations/:id" }, { :name => :family, :class_name => "Family", :foreign_key => "family_id", :path => "/families/:id" }]
    end # }}}
  end

  context "setting relationships with details" do
    before do # {{{
      spawn_model "Foo::User"
    end # }}}

    it "handles a single 'has_many' relationship" do # {{{
      Foo::User.has_many :comments, :class_name => "Post"
      Foo::User.relationships[:has_many].should == [{ :name => :comments, :class_name => "Post", :path => "/comments" }]
    end # }}}

    it "handles a single 'has_one' relationship" do # {{{
      Foo::User.has_one :category, :class_name => "Topic", :foreign_key => "topic_id"
      Foo::User.relationships[:has_one].should == [{ :name => :category, :class_name => "Topic", :foreign_key => "topic_id", :path => "/category" }]
    end # }}}

    it "handles a single belongs_to relationship" do # {{{
      Foo::User.belongs_to :organization, :class_name => "Business", :foreign_key => "org_id"
      Foo::User.relationships[:belongs_to].should == [{ :name => :organization, :class_name => "Business", :foreign_key => "org_id", :path => "/organizations/:id" }]
    end # }}}
  end

  context "handling relationships without details" do
    before do # {{{
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { :id => 1, :name => "Tobias Fünke", :comments => [{ :id => 2, :body => "Tobias, you blow hard!" }, { :id => 3, :body => "I wouldn't mind kissing that man between the cheeks, so to speak" }], :role => { :id => 1, :body => "Admin" }, :organization => { :id => 1, :name => "Bluth Company" }, :organization_id => 1 }.to_json] }
          stub.get("/users/2") { |env| [200, {}, { :id => 2, :name => "Lindsay Fünke", :organization_id => 1 }.to_json] }
          stub.get("/users/2/comments") { |env| [200, {}, [{ :id => 4, :body => "They're having a FIRESALE?" }, { :id => 5, :body => "Is this the tiny town from Footloose?" }].to_json] }
          stub.get("/users/2/role") { |env| [200, {}, { :id => 2, :body => "User" }.to_json] }
          stub.get("/organizations/1") { |env| [200, {}, { :id => 1, :name => "Bluth Company" }.to_json] }
        end
      end

      spawn_model "Foo::User" do
        has_many :comments
        has_one :role
        belongs_to :organization
      end

      spawn_model "Foo::Organization"
      spawn_model "Foo::Comment"
      spawn_model "Foo::Role"

      @user_with_included_data = Foo::User.find(1)
      @user_without_included_data = Foo::User.find(2)
    end # }}}

    it "maps an array of included data through has_many" do # {{{
      @user_with_included_data.comments.first.should be_a(Foo::Comment)
      @user_with_included_data.comments.length.should == 2
      @user_with_included_data.comments.first.id.should == 2
      @user_with_included_data.comments.first.body.should == "Tobias, you blow hard!"
    end # }}}

    it "fetches data that was not included through has_many" do # {{{
      @user_without_included_data.comments.first.should be_a(Foo::Comment)
      @user_without_included_data.comments.length.should == 2
      @user_without_included_data.comments.first.id.should == 4
      @user_without_included_data.comments.first.body.should == "They're having a FIRESALE?"
    end # }}}

    it "maps an array of included data through has_one" do # {{{
      @user_with_included_data.role.should be_a(Foo::Role)
      @user_with_included_data.role.id.should == 1
      @user_with_included_data.role.body.should == "Admin"
    end # }}}

    it "fetches data that was not included through has_one" do # {{{
      @user_without_included_data.role.should be_a(Foo::Role)
      @user_without_included_data.role.id.should == 2
      @user_without_included_data.role.body.should == "User"
    end # }}}

    it "maps an array of included data through belongs_to" do # {{{
      @user_with_included_data.organization.should be_a(Foo::Organization)
      @user_with_included_data.organization.id.should == 1
      @user_with_included_data.organization.name.should == "Bluth Company"
    end # }}}

    it "fetches data that was not included through belongs_to" do # {{{
      @user_without_included_data.organization.should be_a(Foo::Organization)
      @user_without_included_data.organization.id.should == 1
      @user_without_included_data.organization.name.should == "Bluth Company"
    end # }}}
  end

  context "handling relationships with details" do
    before do # {{{
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { :id => 1, :name => "Tobias Fünke", :organization => { :id => 1, :name => "Bluth Company" }, :organization_id => 1 }.to_json] }
          stub.get("/users/2") { |env| [200, {}, { :id => 2, :name => "Lindsay Fünke", :organization_id => 1 }.to_json] }
          stub.get("/users/3") { |env| [200, {}, { :id => 2, :name => "Lindsay Fünke", :organization => nil }.to_json] }
          stub.get("/companies/1") { |env| [200, {}, { :id => 1, :name => "Bluth Company" }.to_json] }
        end
      end

      spawn_model "Foo::User" do
        belongs_to :company, :path => "/organizations/:id", :foreign_key => :organization_id
      end

      spawn_model "Foo::Company"

      @user_with_included_data = Foo::User.find(1)
      @user_without_included_data = Foo::User.find(2)
      @user_with_included_nil_data = Foo::User.find(3)
    end # }}}

    it "maps an array of included data through belongs_to" do # {{{
      @user_with_included_data.company.should be_a(Foo::Company)
      @user_with_included_data.company.id.should == 1
      @user_with_included_data.company.name.should == "Bluth Company"
    end # }}}

    it "does not map included data if it’s nil" do # {{{
      @user_with_included_nil_data.organization.should be_nil
    end # }}}

    it "fetches data that was not included through belongs_to" do # {{{
      @user_without_included_data.company.should be_a(Foo::Company)
      @user_without_included_data.company.id.should == 1
      @user_without_included_data.company.name.should == "Bluth Company"
    end # }}}
  end
end
