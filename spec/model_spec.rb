# encoding: utf-8
require File.join(File.dirname(__FILE__), "spec_helper.rb")

describe Her::Model do
  context "relationships" do
    describe "setting associations" do # {{{
      before do # {{{
        User = Class.new # FIXME There has to be a better way to reset the class…
        class User
          include Her::Model
        end
      end # }}}

      it "handles a single 'has_many' association" do # {{{
        User.has_many :comments
        User.relationships[:has_many].should == [{ :name => :comments }]
      end # }}}

      it "handles multiples 'has_many' associations" do # {{{
        User.has_many :comments
        User.has_many :posts
        User.relationships[:has_many].should == [{ :name => :comments }, { :name => :posts }]
      end # }}}

      it "handles a single belongs_to association" do # {{{
        User.belongs_to :organization
        User.relationships[:belongs_to].should == [{ :name => :organization }]
      end # }}}

      it "handles multiples 'belongs_to' associations" do # {{{
        User.belongs_to :organization
        User.belongs_to :family
        User.relationships[:belongs_to].should == [{ :name => :organization }, { :name => :family }]
      end # }}}
    end # }}}
  end
end
