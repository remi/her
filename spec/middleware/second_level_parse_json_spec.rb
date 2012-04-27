# encoding: utf-8
require "spec_helper"

describe Her::Middleware::SecondLevelParseJSON do
  subject { described_class.new }
  let(:body) { "{\"data\": 1, \"errors\": 2, \"metadata\": 3}" }

  it "parses body as json" do
    subject.parse(body).tap do |json|
      json[:data].should == 1
      json[:errors].should == 2
      json[:metadata].should == 3
    end
  end

  it "parses :body key as json in the env hash" do
    env = { :body => body }
    subject.on_complete(env)
    env[:body].tap do |json|
      json[:data].should == 1
      json[:errors].should == 2
      json[:metadata].should == 3
    end
  end
end
