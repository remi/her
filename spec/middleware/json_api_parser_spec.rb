# encoding: utf-8
require "spec_helper"

describe Her::Middleware::JsonApiParser do
  subject { described_class.new }

  context "with valid JSON body" do
    let(:body) { '{"data": {"type": "foo", "id": "bar", "attributes": {"baz": "qux"} }, "meta": {"api": "json api"} }' }
    let(:env) { { body: body } }

    it "parses body as json" do
      subject.on_complete(env)
      env.fetch(:body).tap do |json|
        expect(json[:data]).to eql(
          type: "foo",
          id: "bar",
          attributes: { baz: "qux" }
        )
        expect(json[:errors]).to eql([])
        expect(json[:metadata]).to eql(api: "json api")
      end
    end
  end

  context "with status code 204" do
    it "returns an empty body" do
      env = { status: 204 }
      subject.on_complete(env)
      env[:body].tap do |json|
        expect(json[:data]).to eq({})
      end
    end
  end

  context 'with status code 304' do
    it 'returns an empty body' do
      env = { :status => 304 }
      subject.on_complete(env)
      env[:body].tap do |json|
        expect(json[:data]).to eq({})
      end
    end
  end

  # context "with invalid JSON body" do
  #  let(:body) { '"foo"' }
  #  it 'ensures that invalid JSON throws an exception' do
  #    expect { subject.parse(body) }.to raise_error(Her::Errors::ParseError, 'Response from the API must behave like a Hash or an Array (last JSON response was "\"foo\"")')
  #  end
  # end
end
