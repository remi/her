# encoding: utf-8
require "spec_helper"

describe Her::Model::Associations::AssociationProxy do
  describe "proxy assignment methods" do
    before do
      Her::API.setup url: "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { [200, {}, { id: 1, name: "Tobias Fünke" }.to_json] }
          stub.get("/users/1/fish") { [200, {}, { id: 1, name: "Tobias's Fish" }.to_json] }
        end
      end
      spawn_model "User" do
        has_one :fish
      end
      spawn_model "Fish"
    end

    subject { User.find(1) }

    it "should assign value" do
      subject.fish.name = "Fishy"
      expect(subject.fish.name).to eq "Fishy"
    end
  end
end
