# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe Her::Model::Introspection do
  context "introspecting a resource" do
    before do # {{{
      Her::API.setup :base_uri => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.use Faraday::Adapter::NetHttp
      end

      FakeWeb.register_uri(:get, "https://api.example.com/users/1", :body => { :id => 1, :name => "Tobias Funke" }.to_json)
      spawn_model "Foo::User"
    end # }}}

    describe "#inspect" do
      it "outputs resource attributs for an existing resource" do # {{{
        @user = Foo::User.find(1)
        ["#<Foo::User(/users/1) name=\"Tobias Funke\" id=1>", "#<Foo::User(/users/1) id=1 name=\"Tobias Funke\">"].should include(@user.inspect)
      end # }}}

      it "outputs resource attributs for an not-saved-yet resource" do # {{{
        @user = Foo::User.new(:name => "Tobias Funke")
        @user.inspect.should == "#<Foo::User(/users) name=\"Tobias Funke\">"
      end # }}}
    end
  end

  describe "#nearby_class" do
    context "for a class inside of a module" do
      before do
        spawn_model "Foo::User"
        spawn_model "Foo::AccessRecord"
        spawn_model "AccessRecord"
        spawn_model "Log"
      end

      it "returns a sibling class, if found" do
        Foo::User.nearby_class("AccessRecord").should == Foo::AccessRecord
        AccessRecord.nearby_class("Log").should == Log
        Foo::User.nearby_class("Log").should == Log
        Foo::User.nearby_class("X").should be_nil
      end
    end
  end
end
