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
  end
end
