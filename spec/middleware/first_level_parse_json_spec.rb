# encoding: utf-8
require "spec_helper"

describe Her::Middleware::FirstLevelParseJSON do
  subject { described_class.new }
  let(:body) { "{\"id\": 1, \"name\": \"Tobias Fünke\", \"errors\": 2, \"metadata\": 3}" }

  it "parses body as json" do
    subject.parse(body).tap do |json|
      json[:data].should == { :id => 1, :name => "Tobias Fünke" }
      json[:errors].should == 2
      json[:metadata].should == 3
    end
  end

  it "parses :body key as json in the env hash" do
    env = { :body => body }
    subject.on_complete(env)
    env[:body].tap do |json|
      json[:data].should == { :id => 1, :name => "Tobias Fünke" }
      json[:errors].should == 2
      json[:metadata].should == 3
    end
  end
end
