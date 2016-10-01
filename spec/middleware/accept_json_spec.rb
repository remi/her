# encoding: utf-8
require "spec_helper"

describe Her::Middleware::AcceptJSON do
  it "adds an Accept header" do
    described_class.new.add_header({}).tap do |headers|
      expect(headers["Accept"]).to eq("application/json")
    end
  end
end
