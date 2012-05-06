# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe Her::Model::Introspection do
  context "introspecting a resource" do
    before do # {{{
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.use Faraday::Adapter::NetHttp
      end

      spawn_model :User
    end # }}}

    describe "#inspect" do
      it "outputs resource attributs for an existing resource" do # {{{
        @user = User.find(1)
        ["#<User(/users/1) name=\"Tobias Funke\" id=1>", "#<User(/users/1) id=1 name=\"Tobias Funke\">"].should include(@user.inspect)
      end # }}}

      it "outputs resource attributs for an not-saved-yet resource" do # {{{
        @user = User.new(:name => "Tobias Funke")
        @user.inspect.should == "#<User(/users) name=\"Tobias Funke\">"
      end # }}}
    end
  end
end
