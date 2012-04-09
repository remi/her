# encoding: utf-8
require File.join(File.dirname(__FILE__), "spec_helper.rb")

describe Her::API do
  context "initialization" do
    describe "#setup" do
      it "sets a base URI" do # {{{
        @api = Her::API.new
        @api.setup :base_uri => "https://api.example.com"
        @api.base_uri.should == "https://api.example.com"
      end # }}}

      it "sets a custom parsing block" do # {{{
        @api = Her::API.new
        @api.setup :base_uri => "https://api.example.com"
        @api.parse_with do |response|
          response.body
        end
        @api.custom_parsing_block?.should be_true
      end # }}}
    end

    describe "#request" do
      before do # {{{
        @api = Her::API.new
        @api.setup :base_uri => "https://api.example.com"
        FakeWeb.register_uri(:get, "https://api.example.com/foo", :body => "Foo, it is.")
      end # }}}

      it "makes HTTP requests" do # {{{
        response = @api.request(:method => :get, :path => "/foo")
        response.body.should == "Foo, it is."
      end # }}}
    end

    describe "#parse" do
      before do # {{{
        @api = Her::API.new
        @api.setup :base_uri => "https://api.example.com"
        FakeWeb.register_uri(:get, "https://api.example.com/users/1", :body => { :data => { :id => 1, :name => "George Michael Bluth" }, :errors => ["This is a single error"], :metadata => { :page => 1, :per_page => 10 }}.to_json)
      end # }}}

      it "parses a request" do # {{{
        @api.parse @api.request(:method => :get, :path => "users/1") do |parsed_data|
          parsed_data[:resource].should == { :id => 1, :name => "George Michael Bluth" }
          parsed_data[:errors].should == ["This is a single error"]
          parsed_data[:metadata].should == { :page => 1, :per_page => 10 }
        end
      end # }}}
    end
  end
end
