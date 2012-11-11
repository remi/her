# encoding: utf-8
require File.join(File.dirname(__FILE__), "spec_helper.rb")

describe Her::API do
  context "initialization" do
    describe ".setup" do
      it "creates a default connection" do
        Her::API.setup :url => "https://api.example.com"
        Her::API.default_api.base_uri.should == "https://api.example.com"
      end
    end

    describe "#setup" do
      it "sets a base URI" do
        @api = Her::API.new
        @api.setup :url => "https://api.example.com"
        @api.base_uri.should == "https://api.example.com"
      end

      it "sets custom middleware with #use" do
        class Foo; end;
        class Bar; end;

        @api = Her::API.new
        @api.setup :url => "https://api.example.com" do |builder|
          builder.use Foo
          builder.use Bar
        end
        @api.connection.builder.handlers.should == [Foo, Bar]
      end

      it "takes custom options" do
        @api = Her::API.new
        @api.setup :foo => { :bar => "baz" }, :url => "https://api.example.com"
        @api.options.should == { :foo => { :bar => "baz" }, :url => "https://api.example.com" }
      end
    end

    describe "#request" do
      it "makes HTTP requests" do
        class SimpleParser < Faraday::Response::Middleware
          def on_complete(env)
            env[:body] = { :data => env[:body] }
          end
        end

        @api = Her::API.new
        @api.setup :url => "https://api.example.com" do |builder|
          builder.use SimpleParser
          builder.use Faraday::Request::UrlEncoded
          builder.adapter :test do |stub|
            stub.get("/foo") { |env| [200, {}, "Foo it is"] }
          end
        end

        parsed_data = @api.request(:_method => :get, :_path => "/foo")
        parsed_data[:data] == "Foo, it is."
      end

      it "makes HTTP requests while specifying custom HTTP headers" do
        class SimpleParser < Faraday::Response::Middleware
          def on_complete(env)
            env[:body] = { :data => env[:body] }
          end
        end

        @api = Her::API.new
        @api.setup :url => "https://api.example.com" do |builder|
          builder.use SimpleParser
          builder.use Faraday::Request::UrlEncoded
          builder.adapter :test do |stub|
            stub.get("/foo") { |env| [200, {}, "Foo it is #{env[:request_headers]["X-Page"]}"] }
          end
        end

        parsed_data = @api.request(:_method => :get, :_path => "/foo", :_headers => { "X-Page" => 2 })
        parsed_data[:data] == "Foo, it is page 2."
      end

      it "parses a request with the default parser" do
        @api = Her::API.new
        @api.setup :url => "https://api.example.com" do |builder|
          builder.use Her::Middleware::FirstLevelParseJSON
          builder.use Faraday::Request::UrlEncoded
          builder.adapter :test do |stub|
            stub.get("/users/1") { |env| [200, {}, MultiJson.dump({ :id => 1, :name => "George Michael Bluth", :errors => ["This is a single error"], :metadata => { :page => 1, :per_page => 10 } })] }
          end
        end
        parsed_data = @api.request(:_method => :get, :_path => "users/1")
        parsed_data[:data].should == { :id => 1, :name => "George Michael Bluth" }
        parsed_data[:errors].should == ["This is a single error"]
        parsed_data[:metadata].should == { :page => 1, :per_page => 10 }
      end

      it "parses a request with a custom parser" do
        class CustomParser < Faraday::Response::Middleware
          def on_complete(env)
            json = MultiJson.load(env[:body], :symbolize_keys => true)
            errors = json.delete(:errors) || []
            metadata = json.delete(:metadata) || {}
            env[:body] = {
              :data => json,
              :errors => errors,
              :metadata => metadata,
            }
          end
        end

        @api = Her::API.new
        @api.setup :url => "https://api.example.com" do |builder|
          builder.use CustomParser
          builder.use Faraday::Request::UrlEncoded
          builder.adapter :test do |stub|
            stub.get("/users/1") { |env| [200, {}, MultiJson.dump(:id => 1, :name => "George Michael Bluth")] }
          end
        end
        parsed_data = @api.request(:_method => :get, :_path => "users/1")
        parsed_data[:data].should == { :id => 1, :name => "George Michael Bluth" }
        parsed_data[:errors].should == []
        parsed_data[:metadata].should == {}
      end
    end
  end
end
