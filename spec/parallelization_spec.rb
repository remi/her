# encoding: utf-8
require 'spec_helper'
require 'webmock'
require 'typhoeus/adapters/faraday'

describe Her::Parallelization do
  before do
    Her::API.setup :url => "http://api.example.com" do |connection|
      connection.use Her::Middleware::FirstLevelParseJSON
      connection.adapter :typhoeus
    end

    spawn_model("Foo::User")
    spawn_model("Foo::Comment")

    module ParallelTest
      extend Her::Parallelization
    end

    WebMock::API.stub_request(:get, "http://api.example.com/users?name=jhon").to_return({
      :status => 200,
      :body => '[{"id":1,"name":"Jhon Smith","age":30},{"id":2,"name":"Jhon AppleSeed","age":10}]',
      :headers => {}
    })

    WebMock::API.stub_request(:get, "http://api.example.com/users?name=mary").to_return({
      :status => 200,
      :body => '[{"id":4,"name":"Mary Jones","age":45}]',
      :headers => {}
    })

    WebMock::API.stub_request(:get, "http://api.example.com/comments").to_return({
      :status => 200,
      :body => '[{"author":1,"comment":"bla bla bla"},{"author":2,"comment":"loren impsun"}]',
      :headers => {}
    })
  end

  describe :in_parallel do
    it 'should collect all requests and return a hash with objects' do
      response = ParallelTest.in_parallel do |queue|
        queue.add Foo::User.where(name: 'jhon')
        queue.add Foo::User.where(name: 'mary')
        queue.add Foo::Comment.all
      end

      response.length.should == 2
      response[:'foo/users'].length.should == 3
      response[:'foo/comments'].length.should == 2
    end

    it 'should return User and Comment models' do
      response = ParallelTest.in_parallel do |queue|
        queue.add Foo::User.where(name: 'jhon')
        queue.add Foo::User.where(name: 'mary')
        queue.add Foo::Comment.all
      end

      response[:'foo/users'].first.kind_of?(Foo::User).should == true
      response[:'foo/comments'].first.kind_of?(Foo::Comment).should == true
    end

    it 'should return and array of User when only user requests are made' do
      response = ParallelTest.in_parallel do |queue|
        queue.add Foo::User.where(name: 'jhon')
        queue.add Foo::User.where(name: 'mary')
      end

      response.length.should == 3
      response.is_a?(Array).should == true
      response.first.kind_of?(Foo::User).should == true
    end
  end
end
