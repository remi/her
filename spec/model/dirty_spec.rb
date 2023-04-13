# encoding: utf-8

require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe "Restorm::Model and ActiveModel::Dirty" do
  context "checking dirty attributes" do
    before do
      Restorm::API.setup url: "https://api.example.com" do |builder|
        builder.use Restorm::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users")   { [200, {}, [{ id: 1, fullname: "Lindsay Fünke" }, { id: 2, fullname: "Maeby Fünke" }].to_json] }
          stub.get("/users/1") { [200, {}, { id: 1, fullname: "Lindsay Fünke" }.to_json] }
          stub.get("/users/2") { [200, {}, { id: 2, fullname: "Maeby Fünke" }.to_json] }
          stub.get("/users/3") { [200, {}, { user_id: 3, fullname: "Maeby Fünke" }.to_json] }
          stub.put("/users/1") { [200, {}, { id: 1, fullname: "Tobias Fünke" }.to_json] }
          stub.put("/users/2") { [400, {}, { errors: ["Email cannot be blank"] }.to_json] }
          stub.post("/users")  { [200, {}, { id: 1, fullname: "Tobias Fünke" }.to_json] }
          stub.get("/users/1/posts") { [200, {}, [{ id: 1, user_id: 1, body: "Hello" }].to_json] }
          stub.get("/users/1/posts/1") { [200, {}, { id: 1, user_id: 1, body: "Hello" }.to_json] }
        end
      end

      spawn_model "Foo::Post" do
        belongs_to :user
        attributes :body
      end
      spawn_model "Foo::User" do
        has_many :posts
        attributes :fullname, :email
      end
      spawn_model "Dynamic::User" do
        primary_key :user_id
      end
    end

    context "for existing resource" do
      let(:user) { Foo::User.find(1) }
      it "has no changes" do
        expect(user.changes).to be_empty
        expect(user).not_to be_changed
      end
      context "with successful save" do
        it "tracks dirty attributes" do
          user.fullname = "Tobias Fünke"
          expect(user.fullname_changed?).to be_truthy
          expect(user.email_changed?).to be_falsey
          expect(user).to be_changed
          user.save
          expect(user).not_to be_changed
        end

        it "tracks only changed dirty attributes" do
          user.fullname = user.fullname
          expect(user.fullname_changed?).to be_falsey
        end

        it "tracks previous changes" do
          user.fullname = "Tobias Fünke"
          user.save
          expect(user.previous_changes).to eq("fullname" => ["Lindsay Fünke", "Tobias Fünke"])
        end

        it "tracks dirty attribute for mass assign for dynamic created attributes" do
          user = Dynamic::User.find(3)
          user.assign_attributes(fullname: "New Fullname")
          expect(user.fullname_changed?).to be_truthy
          expect(user).to be_changed
          expect(user.changes.length).to eq(1)
        end
      end

      context "with erroneous save" do
        it "tracks dirty attributes" do
          user = Foo::User.find(2)
          user.fullname = "Tobias Fünke"
          expect(user.fullname_changed?).to be_truthy
          expect(user.email_changed?).to be_falsey
          expect(user).to be_changed
          user.save
          expect(user).to be_changed
        end
      end
    end

    context "for an existing resource from an association" do
      let(:post) { Foo::User.find(1).posts.find(1) }
      it "has no changes" do
        expect(post.changes).to be_empty
        expect(post).to_not be_changed
      end
    end

    context "for an existing resource from an association collection" do
      let(:post) { Foo::User.find(1).posts.first }
      it "has no changes" do
        expect(post.changes).to be_empty
        expect(post).to_not be_changed
      end
    end

    context "for resources from a collection" do
      let(:users) { Foo::User.all.fetch }
      it "has no changes" do
        users.each do |user|
          expect(user.changes).to be_empty
          expect(user).to_not be_changed
        end
      end
    end

    context "for new resource" do
      let(:user) { Foo::User.new(fullname: "Lindsay Fünke") }
      it "has changes" do
        expect(user).to be_changed
      end
      it "tracks dirty attributes" do
        user.fullname = "Tobias Fünke"
        expect(user.fullname_changed?).to be_truthy
        expect(user).to be_changed
        user.save
        expect(user).not_to be_changed
      end
    end

    context "for a new resource from an association" do
      let(:post) { Foo::User.find(1).posts.build }
      it "has changes" do
        expect(post).to be_changed
      end
    end
  end
end
