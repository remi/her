# encoding: utf-8
require 'spec_helper'

module FooBarBaz
  class Model
    include Her::Model
  end
  class User < Model
  end
end

describe "inheriting from a base class that includes Her::Model" do
  before do
    Her::API.setup :url => "https://api.example.com" do |connection|
      connection.use Her::Middleware::FirstLevelParseJSON
      connection.adapter :test do |stub|
        stub.get("/users/1") { |env| [200, {}, { :id => 1, :name => "Tobias Fünke" }.to_json] }
      end
    end
  end

  it "should behave like a Her::Model" do
    expect(FooBarBaz::User.find(1).name).to eq "Tobias Fünke" 
  end
end
