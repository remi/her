# encoding: utf-8
require "spec_helper"

describe Her::Middleware::SecondLevelParseJSON do
  subject { described_class.new }

  context "with valid JSON body" do
    let(:body) { "{\"data\": 1, \"errors\": 2, \"metadata\": 3}" }
    it "parses body as json" do
      subject.parse(body).tap do |json|
        expect(json[:data]).to eq(1)
        expect(json[:errors]).to eq(2)
        expect(json[:metadata]).to eq(3)
      end
    end

    it "parses :body key as json in the env hash" do
      env = { body: body }
      subject.on_complete(env)
      env[:body].tap do |json|
        expect(json[:data]).to eq(1)
        expect(json[:errors]).to eq(2)
        expect(json[:metadata]).to eq(3)
      end
    end
  end

  context "with invalid JSON body" do
    let(:body) { '"foo"' }
    it "ensures that invalid JSON throws an exception" do
      expect { subject.parse(body) }.to raise_error(Her::Errors::ParseError, 'Response from the API must behave like a Hash or an Array (last JSON response was "\"foo\"")')
    end
  end
end
