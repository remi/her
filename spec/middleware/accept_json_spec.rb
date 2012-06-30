# encoding: utf-8
require "spec_helper"

describe Her::Middleware::AcceptJSON do
  it "adds an Accept header" do
    described_class.new.add_header({}).tap do |headers|
      headers["Accept"].should == "application/json"
    end
  end
end
