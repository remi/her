# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe Her::Model::ORM do
  context "mapping data to Ruby objects" do
    before do # {{{
      api = Her::API.new
      api.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { :id => 1, :name => "Tobias Fünke" }.to_json] }
          stub.get("/users") { |env| [200, {}, [{ :id => 1, :name => "Tobias Fünke" }, { :id => 2, :name => "Lindsay Fünke" }].to_json] }
          stub.get("/admin_users") { |env| [200, {}, [{ :id => 1, :name => "Tobias Fünke" }, { :id => 2, :name => "Lindsay Fünke" }].to_json] }
        end
      end

      spawn_model "Foo::User" do
        uses_api api
      end

      spawn_model "Foo::AdminUser" do
        uses_api api
      end
    end # }}}

    it "maps a single resource to a Ruby object" do # {{{
      @user = Foo::User.find(1)
      @user.id.should == 1
      @user.name.should == "Tobias Fünke"
    end # }}}

    it "maps a collection of resources to an array of Ruby objects" do # {{{
      @users = Foo::User.all
      @users.length.should == 2
      @users.first.name.should == "Tobias Fünke"

      @users = Foo::AdminUser.all
      @users.length.should == 2
      @users.first.name.should == "Tobias Fünke"
    end # }}}

    it "handles new resource" do # {{{
<<<<<<< HEAD
      @new_user = User.new(:fullname => "Tobias Fünke", :medicine_license => nil)
=======
      @new_user = Foo::User.new(:fullname => "Tobias Fünke")
>>>>>>> Use submodels in orm_spec.rb
      @new_user.new?.should be_true
      @new_user.fullname.should == "Tobias Fünke"
      @new_user.medicine_license.should be_nil

      @existing_user = Foo::User.find(1)
      @existing_user.new?.should be_false
    end # }}}

    it "handles method missing for getter" do# {{{
      @new_user = User.new(:fullname => 'Mayonegg')
      lambda { @new_user.unknown_method_for_a_user }.should raise_error(NoMethodError)
      expect { @new_user.fullname }.to_not raise_error(NoMethodError)
    end# }}}

    it "handles method missing for setter" do# {{{
      @new_user = User.new
      expect { @new_user.fullname = "Tobias Fünke" }.to_not raise_error(NoMethodError)
    end# }}}
  end

  context "mapping data, metadata and error data to Ruby objects" do
    before do # {{{
      api = Her::API.new
      api.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::SecondLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users") { |env| [200, {}, { :data => [{ :id => 1, :name => "Tobias Fünke" }, { :id => 2, :name => "Lindsay Fünke" }], :metadata => { :total_pages => 10, :next_page => 2 }, :errors => ["Oh", "My", "God"] }.to_json] }
          stub.post("/users") { |env| [200, {}, { :data => { :name => "George Michael Bluth" }, :metadata => { :foo => "bar" }, :errors => ["Yes", "Sir"] }.to_json] }
        end
      end

      spawn_model :User do
        uses_api api
      end
    end # }}}

    it "handles metadata on a collection" do # {{{
      @users = User.all
      @users.metadata[:total_pages].should == 10
    end # }}}

    it "handles error data on a collection" do # {{{
      @users = User.all
      @users.errors.length.should == 3
    end # }}}

    it "handles metadata on a resource" do # {{{
      @user = User.create(:name => "George Michael Bluth")
      @user.metadata[:foo].should == "bar"
    end # }}}

    it "handles error data on a resource" do # {{{
      @user = User.create(:name => "George Michael Bluth")
      @user.errors.should == ["Yes", "Sir"]
      @user.should be_invalid
    end # }}}
  end

  context "defining custom getters and setters" do
    before do # {{{
      api = Her::API.new
      api.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { :id => 1, :friends => ["Maeby", "GOB", "Anne"] }.to_json] }
          stub.get("/users/2") { |env| [200, {}, { :id => 1, :organization => true }.to_json] }
        end
      end

      spawn_model :User do
        uses_api api
        belongs_to :organization

        def friends=(val)
          val = val.gsub("\r", "").split("\n").map { |friend| friend.gsub(/^\s*\*\s*/, "") } if val and val.is_a?(String)
          @data[:friends] = val
        end

        def friends
          @data[:friends].map { |friend| "* #{friend}" }.join("\n")
        end

        # Why would anybody want to do this? I don’t know.
        def organization=(organization)
          @data[:organization] = { :foo => :bar }
        end
      end
    end # }}}

    it "handles custom setters" do # {{{
      @user = User.find(1)
      @user.friends.should == "* Maeby\n* GOB\n* Anne"
      @user.instance_eval do
        @data[:friends] = ["Maeby", "GOB", "Anne"]
      end
    end # }}}

    it "handles custom setters with relationships" do # {{{
      @user = User.find(2)
      @user.organization.should == { :foo => :bar }
    end # }}}

    it "handles custom getters" do # {{{
      @user = User.new
      @user.friends = "* George\n* Oscar\n* Lucille"
      @user.friends.should == "* George\n* Oscar\n* Lucille"
      @user.instance_eval do
        @data[:friends] = ["George", "Oscar", "Lucille"]
      end
    end # }}}
  end

  context "creating resources" do
    before do # {{{
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.post("/users") { |env| [200, {}, { :id => 1, :fullname => "Tobias Fünke" }.to_json] }
        end
      end

      spawn_model "Foo::User"
    end # }}}

    it "handle one-line resource creation" do # {{{
      @user = Foo::User.create(:fullname => "Tobias Fünke")
      @user.id.should == 1
      @user.fullname.should == "Tobias Fünke"
    end # }}}

    it "handle resource creation through Model.new + #save" do # {{{
      @user = Foo::User.new(:fullname => "Tobias Fünke")
      @user.save
      @user.fullname.should == "Tobias Fünke"
    end # }}}
  end

  context "updating resources" do
    before do # {{{
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { :id => 1, :fullname => "Tobias Fünke" }.to_json] }
          stub.put("/users/1") { |env| [200, {}, { :id => 1, :fullname => "Lindsay Fünke" }.to_json] }
        end
      end

      spawn_model "Foo::User"
    end # }}}

    it "handle resource data update without saving it" do # {{{
      @user = Foo::User.find(1)
      @user.fullname.should == "Tobias Fünke"
      @user.fullname = "Kittie Sanchez"
      @user.fullname.should == "Kittie Sanchez"
    end # }}}

    it "handle resource update through the .update class method" do # {{{
      @user = Foo::User.save_existing(1, { :fullname => "Lindsay Fünke" })
      @user.fullname.should == "Lindsay Fünke"
    end # }}}

    it "handle resource update through #save on an existing resource" do # {{{
      @user = Foo::User.find(1)
      @user.fullname = "Lindsay Fünke"
      @user.save
      @user.fullname.should == "Lindsay Fünke"
    end # }}}
  end

  context "deleting resources" do
    before do # {{{
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { :id => 1, :fullname => "Tobias Fünke", :active => true }.to_json] }
          stub.delete("/users/1") { |env| [200, {}, { :id => 1, :fullname => "Lindsay Fünke", :active => false }.to_json] }
        end
      end

      spawn_model "Foo::User"
    end # }}}

    it "handle resource deletion through the .destroy class method" do # {{{
      @user = Foo::User.destroy_existing(1)
      @user.active.should be_false
    end # }}}

    it "handle resource deletion through #destroy on an existing resource" do # {{{
      @user = Foo::User.find(1)
      @user.destroy
      @user.active.should be_false
    end # }}}
  end
end
