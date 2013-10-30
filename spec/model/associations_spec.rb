# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe Her::Model::Associations do
  context "setting associations without details" do
    before { spawn_model "Foo::User" }
    subject { Foo::User.associations }

    context "single has_many association" do
      before { Foo::User.has_many :comments }
      its([:has_many]) { should eql [{ :name => :comments, :data_key => :comments, :default => [], :class_name => "Comment", :path => "/comments", :inverse_of => nil }] }
    end

    context "multiple has_many associations" do
      before do
        Foo::User.has_many :comments
        Foo::User.has_many :posts
      end

      its([:has_many]) { should eql [{ :name => :comments, :data_key => :comments, :default => [], :class_name => "Comment", :path => "/comments", :inverse_of => nil }, { :name => :posts, :data_key => :posts, :default => [], :class_name => "Post", :path => "/posts", :inverse_of => nil }] }
    end

    context "single has_one association" do
      before { Foo::User.has_one :category }
      its([:has_one]) { should eql [{ :name => :category, :data_key => :category, :default => nil, :class_name => "Category", :path => "/category" }] }
    end

    context "multiple has_one associations" do
      before do
        Foo::User.has_one :category
        Foo::User.has_one :role
      end

      its([:has_one]) { should eql [{ :name => :category, :data_key => :category, :default => nil, :class_name => "Category", :path => "/category" }, { :name => :role, :data_key => :role, :default => nil, :class_name => "Role", :path => "/role" }] }
    end

    context "single belongs_to association" do
      before { Foo::User.belongs_to :organization }
      its([:belongs_to]) { should eql [{ :name => :organization, :data_key => :organization, :default => nil, :class_name => "Organization", :foreign_key => "organization_id", :path => "/organizations/:id" }] }
    end

    context "multiple belongs_to association" do
      before do
        Foo::User.belongs_to :organization
        Foo::User.belongs_to :family
      end

      its([:belongs_to]) { should eql [{ :name => :organization, :data_key => :organization, :default => nil, :class_name => "Organization", :foreign_key => "organization_id", :path => "/organizations/:id" }, { :name => :family, :data_key => :family, :default => nil, :class_name => "Family", :foreign_key => "family_id", :path => "/families/:id" }] }
    end
  end

  context "setting associations with details" do
    before { spawn_model "Foo::User" }
    subject { Foo::User.associations }

    context "in base class" do
      context "single has_many association" do
        before { Foo::User.has_many :comments, :class_name => "Post", :inverse_of => :admin, :data_key => :user_comments, :default => {} }
        its([:has_many]) { should eql [{ :name => :comments, :data_key => :user_comments, :default => {}, :class_name => "Post", :path => "/comments", :inverse_of => :admin }] }
      end

      context "signle has_one association" do
        before { Foo::User.has_one :category, :class_name => "Topic", :foreign_key => "topic_id", :data_key => :topic, :default => nil }
        its([:has_one]) { should eql [{ :name => :category, :data_key => :topic, :default => nil, :class_name => "Topic", :foreign_key => "topic_id", :path => "/category" }] }
      end

      context "single belongs_to association" do
        before { Foo::User.belongs_to :organization, :class_name => "Business", :foreign_key => "org_id", :data_key => :org, :default => true }
        its([:belongs_to]) { should eql [{ :name => :organization, :data_key => :org, :default => true, :class_name => "Business", :foreign_key => "org_id", :path => "/organizations/:id" }] }
      end
    end

    context "in parent class" do
      before { Foo::User.has_many :comments, :class_name => "Post" }

      describe "associations accessor" do
        subject { Class.new(Foo::User).associations }
        its(:object_id) { should_not eql Foo::User.associations.object_id }
      its([:has_many]) { should eql [{ :name => :comments, :data_key => :comments, :default => [], :class_name => "Post", :path => "/comments", :inverse_of => nil }] }
      end
    end
  end

  context "handling associations without details" do
    before do
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { :id => 1, :name => "Tobias Fünke", :comments => [{ :comment => { :id => 2, :body => "Tobias, you blow hard!", :user_id => 1 } }, { :comment => { :id => 3, :body => "I wouldn't mind kissing that man between the cheeks, so to speak", :user_id => 1 } }], :comment_ids => [2, 3], :role => { :id => 1, :body => "Admin" }, :organization => { :id => 1, :name => "Bluth Company" }, :organization_id => 1 }.to_json] }
          stub.get("/users/2") { |env| [200, {}, { :id => 2, :name => "Lindsay Fünke", :organization_id => 2 }.to_json] }
          stub.get("/users/1/comments") { |env| [200, {}, [{ :comment => { :id => 4, :body => "They're having a FIRESALE?" } }].to_json] }
          stub.get("/users/2/comments") { |env| [200, {}, [{ :comment => { :id => 4, :body => "They're having a FIRESALE?" } }, { :comment => { :id => 5, :body => "Is this the tiny town from Footloose?" } }].to_json] }
          stub.get("/users/2/comments/5") { |env| [200, {}, { :comment => { :id => 5, :body => "Is this the tiny town from Footloose?" } }.to_json] }
          stub.get("/users/2/role") { |env| [200, {}, { :id => 2, :body => "User" }.to_json] }
          stub.get("/users/1/role") { |env| [200, {}, { :id => 3, :body => "User" }.to_json] }
          stub.get("/users/1/posts") { |env| [200, {}, [{:id => 1, :body => 'blogging stuff', :admin_id => 1 }].to_json] }
          stub.get("/organizations/1") { |env| [200, {}, { :organization =>  { :id => 1, :name => "Bluth Company Foo" } }.to_json] }
          stub.post("/users") { |env| [200, {}, { :id => 5, :name => "Mr. Krabs", :comments => [{ :comment => { :id => 99, :body => "Rodríguez, nasibisibusi?", :user_id => 5 } }], :role => { :id => 1, :body => "Admin" }, :organization => { :id => 3, :name => "Krusty Krab" }, :organization_id => 3 }.to_json] }
          stub.put("/users/5") { |env| [200, {}, { :id => 5, :name => "Clancy Brown", :comments => [{ :comment => { :id => 99, :body => "Rodríguez, nasibisibusi?", :user_id => 5 } }], :role => { :id => 1, :body => "Admin" }, :organization => { :id => 3, :name => "Krusty Krab" }, :organization_id => 3 }.to_json] }
          stub.delete("/users/5") { |env| [200, {}, { :id => 5, :name => "Clancy Brown", :comments => [{ :comment => { :id => 99, :body => "Rodríguez, nasibisibusi?", :user_id => 5 } }], :role => { :id => 1, :body => "Admin" }, :organization => { :id => 3, :name => "Krusty Krab" }, :organization_id => 3 }.to_json] }

          stub.get("/organizations/2") do |env|
            if env[:params]["admin"] == "true"
              [200, {}, { :organization => { :id => 2, :name => "Bluth Company (admin)" } }.to_json]
            else
              [200, {}, { :organization => { :id => 2, :name => "Bluth Company" } }.to_json]
            end
          end
        end
      end

      spawn_model "Foo::User" do
        has_many :comments
        has_one :role
        belongs_to :organization
        has_many :posts, :inverse_of => :admin
      end
      spawn_model "Foo::Comment" do
        belongs_to :user
        parse_root_in_json true
      end
      spawn_model "Foo::Post" do
        belongs_to :admin, :class_name => 'Foo::User'
      end

      spawn_model "Foo::Organization" do
        parse_root_in_json true
      end

      spawn_model "Foo::Role"

      @user_with_included_data = Foo::User.find(1)
      @user_without_included_data = Foo::User.find(2)
    end

    let(:user_with_included_data_after_create) { Foo::User.create }
    let(:user_with_included_data_after_save_existing) { Foo::User.save_existing(5, :name => "Clancy Brown") }
    let(:user_with_included_data_after_destroy) { Foo::User.new(:id => 5).destroy }

    it "maps an array of included data through has_many" do
      @user_with_included_data.comments.first.should be_a(Foo::Comment)
      @user_with_included_data.comments.length.should == 2
      @user_with_included_data.comments.first.id.should == 2
      @user_with_included_data.comments.first.body.should == "Tobias, you blow hard!"
    end

    it "does not refetch the parents models data if they have been fetched before" do
      @user_with_included_data.comments.first.user.fetch.object_id.should == @user_with_included_data.object_id
    end

    it "uses the given inverse_of key to set the parent model" do
      @user_with_included_data.posts.first.admin.fetch.object_id.should == @user_with_included_data.object_id
    end

    it "fetches data that was not included through has_many" do
      @user_without_included_data.comments.first.should be_a(Foo::Comment)
      @user_without_included_data.comments.length.should == 2
      @user_without_included_data.comments.first.id.should == 4
      @user_without_included_data.comments.first.body.should == "They're having a FIRESALE?"
    end

    it "fetches has_many data even if it was included, only if called with parameters" do
      @user_with_included_data.comments.where(:foo_id => 1).length.should == 1
    end

    it "provides an array of has_many ids" do
      @user_with_included_data.comment_ids.length.should == 2
      @user_with_included_data.comment_ids.should == [2, 3]
      @user_without_included_data.comment_ids.length.should == 0
      @user_without_included_data.comment_ids.should == []
    end

    it "maps an array of included data through has_one" do
      @user_with_included_data.role.should be_a(Foo::Role)
      @user_with_included_data.role.object_id.should == @user_with_included_data.role.object_id
      @user_with_included_data.role.id.should == 1
      @user_with_included_data.role.body.should == "Admin"
    end

    it "fetches data that was not included through has_one" do
      @user_without_included_data.role.should be_a(Foo::Role)
      @user_without_included_data.role.id.should == 2
      @user_without_included_data.role.body.should == "User"
    end

    it "fetches has_one data even if it was included, only if called with parameters" do
      @user_with_included_data.role.where(:foo_id => 2).id.should == 3
    end

    it "maps an array of included data through belongs_to" do
      @user_with_included_data.organization.should be_a(Foo::Organization)
      @user_with_included_data.organization.id.should == 1
      @user_with_included_data.organization.name.should == "Bluth Company"
    end

    it "fetches data that was not included through belongs_to" do
      @user_without_included_data.organization.should be_a(Foo::Organization)
      @user_without_included_data.organization.id.should == 2
      @user_without_included_data.organization.name.should == "Bluth Company"
    end

    it "fetches belongs_to data even if it was included, only if called with parameters" do
      @user_with_included_data.organization.where(:foo_id => 1).name.should == "Bluth Company Foo"
    end

    it "can tell if it has a association" do
      @user_without_included_data.has_association?(:unknown_association).should be_false
      @user_without_included_data.has_association?(:organization).should be_true
    end

    it "fetches the resource corresponding to a named association" do
      @user_without_included_data.get_association(:unknown_association).should be_nil
      @user_without_included_data.get_association(:organization).name.should == "Bluth Company"
    end

    it "pass query string parameters when additional arguments are passed" do
      @user_without_included_data.organization.where(:admin => true).name.should == "Bluth Company (admin)"
      @user_without_included_data.organization.name.should == "Bluth Company"
    end

    it "fetches data with the specified id when calling find" do
      comment = @user_without_included_data.comments.find(5)
      comment.id.should eq(5)
    end

    it "'s associations responds to #empty?" do
      @user_without_included_data.organization.respond_to?(:empty?).should be_true
      @user_without_included_data.organization.should_not be_empty
    end

    [:create, :save_existing, :destroy].each do |type|
      context "after #{type}" do
        let(:subject) { self.send("user_with_included_data_after_#{type}")}

        it "maps an array of included data through has_many" do
          subject.comments.first.should be_a(Foo::Comment)
          subject.comments.length.should == 1
          subject.comments.first.id.should == 99
          subject.comments.first.body.should == "Rodríguez, nasibisibusi?"
        end

        it "maps an array of included data through has_one" do
          subject.role.should be_a(Foo::Role)
          subject.role.id.should == 1
          subject.role.body.should == "Admin"
        end
      end
    end
  end

  context "handling associations with details" do
    before do
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { :id => 1, :name => "Tobias Fünke", :organization => { :id => 1, :name => "Bluth Company Inc." }, :organization_id => 1 }.to_json] }
          stub.get("/users/2") { |env| [200, {}, { :id => 2, :name => "Lindsay Fünke", :organization_id => 1 }.to_json] }
          stub.get("/users/3") { |env| [200, {}, { :id => 2, :name => "Lindsay Fünke", :company => nil }.to_json] }
          stub.get("/companies/1") { |env| [200, {}, { :id => 1, :name => "Bluth Company" }.to_json] }
        end
      end

      spawn_model "Foo::User" do
        belongs_to :company, :path => "/organizations/:id", :foreign_key => :organization_id, :data_key => :organization
      end

      spawn_model "Foo::Company"

      @user_with_included_data = Foo::User.find(1)
      @user_without_included_data = Foo::User.find(2)
      @user_with_included_nil_data = Foo::User.find(3)
    end

    it "maps an array of included data through belongs_to" do
      @user_with_included_data.company.should be_a(Foo::Company)
      @user_with_included_data.company.id.should == 1
      @user_with_included_data.company.name.should == "Bluth Company Inc."
    end

    it "does not map included data if it’s nil" do
      @user_with_included_nil_data.company.should be_nil
    end

    it "fetches data that was not included through belongs_to" do
      @user_without_included_data.company.should be_a(Foo::Company)
      @user_without_included_data.company.id.should == 1
      @user_without_included_data.company.name.should == "Bluth Company"
    end
  end

  context "building and creating association data" do
    before do
      spawn_model "Foo::Comment"
      spawn_model "Foo::User" do
        has_many :comments
      end
    end

    context "with #build" do
      it "takes the parent primary key" do
        @comment = Foo::User.new(:id => 10).comments.build(:body => "Hello!")
        @comment.body.should == "Hello!"
        @comment.user_id.should == 10
      end
    end

    context "with #create" do
      before do
        Her::API.setup :url => "https://api.example.com" do |builder|
          builder.use Her::Middleware::FirstLevelParseJSON
          builder.use Faraday::Request::UrlEncoded
          builder.adapter :test do |stub|
            stub.get("/users/10") { |env| [200, {}, { :id => 10 }.to_json] }
            stub.post("/comments") { |env| [200, {}, { :id => 1, :body => Faraday::Utils.parse_query(env[:body])['body'], :user_id => Faraday::Utils.parse_query(env[:body])['user_id'].to_i }.to_json] }
          end
        end

        Foo::User.use_api Her::API.default_api
        Foo::Comment.use_api Her::API.default_api
      end

      it "takes the parent primary key and saves the resource" do
        @user = Foo::User.find(10)
        @comment = @user.comments.create(:body => "Hello!")
        @comment.id.should == 1
        @comment.body.should == "Hello!"
        @comment.user_id.should == 10
        @user.comments.should == [@comment]
      end
    end
  end
end
