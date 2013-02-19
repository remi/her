# encoding: utf-8
require "spec_helper"

describe Her::Middleware::FirstLevelParseJSON do
  subject { described_class.new }
  let(:body_without_errors) { "{\"id\": 1, \"name\": \"Tobias Fünke\", \"metadata\": 3}" }
  let(:body_with_errors) { "{\"id\": 1, \"name\": \"Tobias Fünke\", \"errors\": { \"name\": [ \"not_valid\", \"should_be_present\" ] }, \"metadata\": 3}" }

  it "parses body as json" do
    subject.parse(body_without_errors).tap do |json|
      json[:data].should == { :id => 1, :name => "Tobias Fünke" }
      json[:metadata].should == 3
    end
  end

  it "parses :body key as json in the env hash" do
    env = { :body => body_without_errors }
    subject.on_complete(env)
    env[:body].tap do |json|
      json[:data].should == { :id => 1, :name => "Tobias Fünke" }
      json[:metadata].should == 3
    end
  end

  it 'ensures the errors are a hash if there are no errors' do
    subject.parse(body_without_errors)[:errors].should eq({})
  end

  it 'ensures the errors are a hash if there are no errors' do
    subject.parse(body_with_errors)[:errors].should eq({:name => [ 'not_valid', 'should_be_present']})
  end

  context 'with status code 204' do
    it 'returns an empty body' do
      env = { :status => 204 }
      subject.on_complete(env)
      env[:body].tap do |json|
        json[:data].should == { }
      end
    end
  end
end
