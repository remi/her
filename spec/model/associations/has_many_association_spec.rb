# encoding: utf-8
require File.join(File.dirname(__FILE__), "../../spec_helper.rb")

describe Her::Model::Associations do
  context "for has_many association" do
    #--------------------------------------------------------------------------------------------
    # Her::Model::Associations#has_many
    #--------------------------------------------------------------------------------------------
    describe :has_many do
      before do
        spawn_model 'Foo::User'
        Foo::User.has_many :comments, comments_options
        Foo::User.has_many :posts, posts_options
      end

      subject { Foo::User.associations }

      let(:comments_options) { {} }
      let(:posts_options) { {} }

      context "without additional options" do
        its([:has_many]) do
          should == [
            { :name => :comments, :data_key => :comments, :class_name => "Comment", :path => "/comments", :inverse_of => nil },
            { :name => :posts, :data_key => :posts, :class_name => "Post", :path => "/posts", :inverse_of => nil }
          ]
        end
      end

      context "without additional options" do
        let(:comments_options) { { :class_name => "Post", :inverse_of => :admin, :data_key => :user_comments } }

        its([:has_many]) do
          should == [
            { :name => :comments, :data_key => :user_comments, :class_name => "Post", :path => "/comments", :inverse_of => :admin },
            { :name => :posts, :data_key => :posts, :class_name => "Post", :path => "/posts", :inverse_of => nil }
          ]
        end
      end

      describe "subclass associations" do
        let(:comments_options) { { :class_name => "Post", :inverse_of => :admin, :data_key => :user_comments } }
        let(:subclass) { Class.new(Foo::User) }

        specify do
          subclass.associations.object_id.should_not == Foo::User.associations.object_id
          subclass.associations[:has_many].length.should == 2
          subclass.associations[:has_many].first[:class_name].should == "Post"
        end
      end
    end

    #--------------------------------------------------------------------------------------------
    # Her::Model::Associations#parse_associations
    #--------------------------------------------------------------------------------------------
    describe :parse_associations do
      context "when association data is present" do
        context "without additional association options" do
          before do
            spawn_model('Foo::User') { has_many :comments }
            spawn_model('Foo::Comment') { parse_root_in_json true }

            stub_api_for(Foo::User) do |stub|
              stub.get("/users/1") { ok! :id => 1, :name => "Tobias Fünke", :comments => [{ :comment => { :id => 2, :body => "Tobias, you blow hard!", :user_id => 1 } }, { :comment => { :id => 3, :body => "I wouldn't mind kissing that man between the cheeks, so to speak", :user_id => 1 } }] }
            end

            stub_api_for(Foo::Comment) do |stub|
              stub.get("/users/1/comments") { ok! [] }
            end
          end

          let(:user) { Foo::User.find(1) }
          subject { user.comments.first }

          its(:id) { should == 2 }
          its(:body) { should == "Tobias, you blow hard!" }
          its(:user) { should == user }

          context "when calling the association method with extra parameters" do
            subject { user.comments(:awaiting_moderation => 1) }
            it { should be_empty }
          end
        end

        context "with additional association options" do
          before do
            spawn_model('Foo::User') { has_many :comments, :class_name => "UserComment", :data_key => :user_comments }
            spawn_model('Foo::UserComment') { parse_root_in_json true }

            stub_api_for(Foo::User) do |stub|
              stub.get("/users/1") { ok! :id => 1, :name => "Tobias Fünke", :user_comments => [{ :user_comment => { :id => 2, :body => "Tobias, you blow hard!", :user_id => 1 } }, { :user_comment => { :id => 3, :body => "I wouldn't mind kissing that man between the cheeks, so to speak", :user_id => 1 } }] }
            end
          end

          let(:user) { Foo::User.find(1) }
          subject { user.comments.first }

          its(:id) { should == 2 }
          its(:body) { should == "Tobias, you blow hard!" }
          its(:user) { should == user }
        end
      end

      context "when association data is nil" do
        context "for has_many association" do
          before do
            spawn_model('Foo::User') { has_many :comments }

            stub_api_for(Foo::User) do |stub|
              stub.get("/users/1") { ok! :id => 1, :name => "Tobias Fünke", :comments => [] }
            end
          end

          subject { Foo::User.find(1).comments }
          it { should be_kind_of(Her::Collection) }
          it { should be_empty }
        end
      end
    end

    #--------------------------------------------------------------------------------------------
    # Her::Model::Associations#fetch_association
    #--------------------------------------------------------------------------------------------
    describe :fetch_association do
      context "without additional association options" do
        # TODO
      end

      context "with additional association options" do
        # TODO
      end
    end
  end
end
