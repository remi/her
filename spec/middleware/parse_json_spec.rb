# encoding: utf-8
require "spec_helper"

describe Her::Middleware::ParseJSON do
  subject { described_class.new }

  let(:date_time) { Time.new }
  let(:hash_with_date) { "{\"id\": 1, \"name\": \"Tobias Fünke\", \"date\": \"#{date_time}\"}" }
  let(:array_with_date) { "[{\"id\": 1, \"name\": \"Tobias Fünke\", \"date\": \"#{date_time}\"}]" }

  it "parses dates in hashes" do
    subject.parse_json(hash_with_date).tap do |json|
      json[:date].to_i.should == date_time.to_i
    end
  end

  it "parses dates in arrays" do
    subject.parse_json(array_with_date).tap do |json|
      json[0][:date].to_i.should == date_time.to_i
    end
  end
end