# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe Her::Model::Introspection do
  context "introspecting a resource" do
    before do
      Her::API.setup url: "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.post("/users")     { [200, {}, { id: 1, name: "Tobias Funke" }.to_json] }
          stub.get("/users/1")    { [200, {}, { id: 1, name: "Tobias Funke" }.to_json] }
          stub.put("/users/1")    { [200, {}, { id: 1, name: "Tobias Funke" }.to_json] }
          stub.delete("/users/1") { [200, {}, { id: 1, name: "Tobias Funke" }.to_json] }
          stub.get("/projects/1/comments") { [200, {}, [{ id: 1, body: "Hello!" }].to_json] }
        end
      end

      spawn_model "Foo::User"
      spawn_model "Foo::Comment" do
        collection_path "projects/:project_id/comments"
      end
    end

    describe "#inspect" do
      it "outputs resource attributes for an existing resource" do
        @user = Foo::User.find(1)
        expect(["#<Foo::User(users/1) name=\"Tobias Funke\" id=1>", "#<Foo::User(users/1) id=1 name=\"Tobias Funke\">"]).to include(@user.inspect)
      end

      it "outputs resource attributes for an not-saved-yet resource" do
        @user = Foo::User.new(name: "Tobias Funke")
        expect(@user.inspect).to eq("#<Foo::User(users) name=\"Tobias Funke\">")
      end

      it "outputs resource attributes using getters" do
        @user = Foo::User.new(name: "Tobias Funke", password: "Funke")
        @user.instance_eval do
          def password
            "filtered"
                             end
        end
        expect(@user.inspect).to include("name=\"Tobias Funke\"")
        expect(@user.inspect).to include("password=\"filtered\"")
        expect(@user.inspect).not_to include("password=\"Funke\"")
      end

      it "support dash on attribute" do
        @user = Foo::User.new(:'life-span' => "3 years")
        expect(@user.inspect).to include("life-span=\"3 years\"")
      end
    end

    describe "#inspect with errors in resource path" do
      it "prints the resource path as “unknown”" do
        @comment = Foo::Comment.where(project_id: 1).first
        path = "<unknown path, missing `project_id`>"
        expect(["#<Foo::Comment(#{path}) body=\"Hello!\" id=1>", "#<Foo::Comment(#{path}) id=1 body=\"Hello!\">"]).to include(@comment.inspect)
      end
    end
  end

  describe "#her_nearby_class" do
    context "for a class inside of a module" do
      before do
        spawn_model "Foo::User"
        spawn_model "Foo::AccessRecord"
        spawn_model "AccessRecord"
        spawn_model "Log"
      end

      it "returns a sibling class, if found" do
        expect(Foo::User.her_nearby_class("AccessRecord")).to eq(Foo::AccessRecord)
        expect(AccessRecord.her_nearby_class("Log")).to eq(Log)
        expect(Foo::User.her_nearby_class("Log")).to eq(Log)
        expect(Foo::User.her_nearby_class("X")).to be_nil
      end
    end
  end
end
