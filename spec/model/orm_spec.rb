# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe Her::Model::ORM do
  context "mapping data to Ruby objects" do
    before do
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
    end

    it "maps a single resource to a Ruby object" do
      @user = Foo::User.find(1)
      @user.id.should == 1
      @user.name.should == "Tobias Fünke"
    end

    it "maps a collection of resources to an array of Ruby objects" do
      @users = Foo::User.all
      @users.length.should == 2
      @users.first.name.should == "Tobias Fünke"

      @users = Foo::AdminUser.all
      @users.length.should == 2
      @users.first.name.should == "Tobias Fünke"
    end

    it "handles new resource" do
      @new_user = Foo::User.new(:fullname => "Tobias Fünke")
      @new_user.new?.should be_true
      @new_user.fullname.should == "Tobias Fünke"

      @existing_user = Foo::User.find(1)
      @existing_user.new?.should be_false
    end

    it "accepts new resource with strings as hash keys" do
      @new_user = Foo::User.new('fullname' => "Tobias Fünke")
      @new_user.fullname.should == "Tobias Fünke"
    end

    it "handles method missing for getter" do
      @new_user = Foo::User.new(:fullname => 'Mayonegg')
      lambda { @new_user.unknown_method_for_a_user }.should raise_error(NoMethodError)
      expect { @new_user.fullname }.to_not raise_error(NoMethodError)
    end

    it "handles method missing for setter" do
      @new_user = Foo::User.new
      expect { @new_user.fullname = "Tobias Fünke" }.to_not raise_error(NoMethodError)
    end

    it "handles method missing for query" do
      @new_user = Foo::User.new
      expect { @new_user.fullname? }.to_not raise_error(NoMethodError)
    end

    it "handles respond_to for getter" do
      @new_user = Foo::User.new(:fullname => 'Mayonegg')
      @new_user.should_not respond_to(:unknown_method_for_a_user)
      @new_user.should respond_to(:fullname)
    end

    it "handles respond_to for setter" do
      @new_user = Foo::User.new
      @new_user.should respond_to(:fullname=)
    end

    it "handles respond_to for query" do
      @new_user = Foo::User.new
      @new_user.should respond_to(:fullname?)
    end

    it "handles has_data? for getter" do
      @new_user = Foo::User.new(:fullname => 'Mayonegg')
      @new_user.should_not have_data(:unknown_method_for_a_user)
      @new_user.should have_data(:fullname)
    end

    it "handles get_data for getter" do
      @new_user = Foo::User.new(:fullname => 'Mayonegg')
      @new_user.get_data(:unknown_method_for_a_user).should be_nil
      @new_user.get_data(:fullname).should == 'Mayonegg'
    end
  end

  context "mapping data, metadata and error data to Ruby objects" do
    before do
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
    end

    it "handles metadata on a collection" do
      @users = User.all
      @users.metadata[:total_pages].should == 10
    end

    it "handles error data on a collection" do
      @users = User.all
      @users.errors.length.should == 3
    end

    it "handles metadata on a resource" do
      @user = User.create(:name => "George Michael Bluth")
      @user.metadata[:foo].should == "bar"
    end

    it "handles error data on a resource" do
      @user = User.create(:name => "George Michael Bluth")
      @user.errors.should == ["Yes", "Sir"]
      @user.should be_invalid
    end
  end

  context "defining custom getters and setters" do
    before do
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
    end

    it "handles custom setters" do
      @user = User.find(1)
      @user.friends.should == "* Maeby\n* GOB\n* Anne"
      @user.instance_eval do
        @data[:friends] = ["Maeby", "GOB", "Anne"]
      end
    end

    it "handles custom setters with relationships" do
      @user = User.find(2)
      @user.organization.should == { :foo => :bar }
    end

    it "handles custom getters" do
      @user = User.new
      @user.friends = "* George\n* Oscar\n* Lucille"
      @user.friends.should == "* George\n* Oscar\n* Lucille"
      @user.instance_eval do
        @data[:friends] = ["George", "Oscar", "Lucille"]
      end
    end
  end

  context "finding resources" do
    before do
      api = Her::API.new
      api.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { :id => 1, :age => 42 }.to_json] }
          stub.get("/users/2") { |env| [200, {}, { :id => 2, :age => 34 }.to_json] }
          stub.get("/users?age=42") { |env| [200, {}, [{ :id => 1, :age => 42 }].to_json] }
        end
      end

      spawn_model :User do
        uses_api api
      end
    end

    it "handles finding by a single id" do
      @user = User.find(1)
      @user.id.should == 1
    end

    it "handles finding by multiple ids" do
      @users = User.find(1, 2)
      @users.should be_kind_of(Array)
      @users.length.should == 2
      @users[0].id.should == 1
      @users[1].id.should == 2
    end

    it "handles finding by an array of ids" do
      @users = User.find([1, 2])
      @users.should be_kind_of(Array)
      @users.length.should == 2
      @users[0].id.should == 1
      @users[1].id.should == 2
    end

    it "handles finding by an array of ids of length 1" do
      @users = User.find([1])
      @users.should be_kind_of(Array)
      @users.length.should == 1
      @users[0].id.should == 1
    end

    it "handles finding with other parameters" do
      @users = User.all(:age => 42)
      @users.should be_kind_of(Array)
      @users.should be_all { |u| u.age == 42 }
    end
  end

  context "creating resources" do
    before do
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.post("/users") { |env| [200, {}, { :id => 1, :fullname => "Tobias Fünke" }.to_json] }
          stub.post("/companies") { |env| [200, {}, { :errors => ["name is required"] }.to_json] }
        end
      end

      spawn_model "Foo::User"
      spawn_model "Foo::Company"
    end

    it "handle one-line resource creation" do
      @user = Foo::User.create(:fullname => "Tobias Fünke")
      @user.id.should == 1
      @user.fullname.should == "Tobias Fünke"
    end

    it "handle resource creation through Model.new + #save" do
      @user = Foo::User.new(:fullname => "Tobias Fünke")
      @user.save.should be_true
      @user.fullname.should == "Tobias Fünke"
    end

    it "returns false when #save gets errors" do
      @company = Foo::Company.new
      @company.save.should be_false
    end

    it "don't overwrite data if response is empty" do
      @company = Foo::Company.new(:name => 'Company Inc.')
      @company.save.should be_false
      @company.name.should == "Company Inc."
    end
  end

  context "updating resources" do
    before do
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { :id => 1, :fullname => "Tobias Fünke" }.to_json] }
          stub.put("/users/1") { |env| [200, {}, { :id => 1, :fullname => "Lindsay Fünke" }.to_json] }
        end
      end

      spawn_model "Foo::User"
    end

    it "handle resource data update without saving it" do
      @user = Foo::User.find(1)
      @user.fullname.should == "Tobias Fünke"
      @user.fullname = "Kittie Sanchez"
      @user.fullname.should == "Kittie Sanchez"
    end

    it "handle resource update through the .update class method" do
      @user = Foo::User.save_existing(1, { :fullname => "Lindsay Fünke" })
      @user.fullname.should == "Lindsay Fünke"
    end

    it "handle resource update through #save on an existing resource" do
      @user = Foo::User.find(1)
      @user.fullname = "Lindsay Fünke"
      @user.save
      @user.fullname.should == "Lindsay Fünke"
    end
  end

  context "assigning new resource data" do
    before do
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { :id => 1, :fullname => "Tobias Fünke", :active => false }.to_json] }
        end
      end

      spawn_model "Foo::User"
      spawn_model "Foo::Comment"
      Foo::User.has_many :comments

      @user = Foo::User.find(1)
    end

    it "handles data update through #assign_attributes" do
      @user.assign_attributes :active => true, :comments => [{ :id => 1, :body => 'Some text' }]
      @user.fullname.should == "Tobias Fünke"
      @user.should be_active
      @user.comments.first.body.should == 'Some text'
    end

    it "handles data update through #reload_data" do
      @user.reload_data({:data => {:active => true, :comments => [{ :id => 1, :body => 'Some text' }]}})
      @user.respond_to?(:fullname, true).should == false
      @user.should be_active
      @user.comments.first.body.should == 'Some text'
    end
  end

  context "deleting resources" do
    before do
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { :id => 1, :fullname => "Tobias Fünke", :active => true }.to_json] }
          stub.delete("/users/1") { |env| [200, {}, { :id => 1, :fullname => "Lindsay Fünke", :active => false }.to_json] }
        end
      end

      spawn_model "Foo::User"
    end

    it "handle resource deletion through the .destroy class method" do
      @user = Foo::User.destroy_existing(1)
      @user.active.should be_false
    end

    it "handle resource deletion through #destroy on an existing resource" do
      @user = Foo::User.find(1)
      @user.destroy
      @user.active.should be_false
    end
  end

  context "saving resources with overridden to_params" do
    before do
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.post("/users") do |env|
            body = {
              :id => 1,
              :fullname => Faraday::Utils.parse_query(env[:body])['fullname']
            }.to_json
            [200, {}, body]
          end
        end
      end

      spawn_model "Foo::User" do
        def to_params
          { :fullname => "Lindsay Fünke" }
        end
      end
    end

    it "changes the request parameters for one-line resource creation" do
      @user = Foo::User.create(:fullname => "Tobias Fünke")
      @user.fullname.should == "Lindsay Fünke"
    end

    it "changes the request parameters for Model.new + #save" do
      @user = Foo::User.new(:fullname => "Tobias Fünke")
      @user.save
      @user.fullname.should == "Lindsay Fünke"
    end
  end

  context "checking resource equality" do
    before do
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { :id => 1, :fullname => "Lindsay Fünke" }.to_json] }
          stub.get("/users/2") { |env| [200, {}, { :id => 1, :fullname => "Tobias Fünke" }.to_json] }
          stub.get("/admins/1") { |env| [200, {}, { :id => 1, :fullname => "Lindsay Fünke" }.to_json] }
        end
      end

      spawn_model "Foo::User"
      spawn_model "Foo::Admin"
    end

    let(:user) { Foo::User.find(1) }

    it "returns true for the exact same object" do
      user.should == user
    end

    it "returns true for the same resource via find" do
      user.should == Foo::User.find(1)
    end

    it "returns true for the same class with identical data" do
      user.should == Foo::User.new(:id => 1, :fullname => "Lindsay Fünke")
    end

    it "returns true for a different resource with the same data" do
      user.should == Foo::Admin.find(1)
    end

    it "returns false for the same class with different data" do
      user.should_not == Foo::User.new(:id => 2, :fullname => "Tobias Fünke")
    end

    it "returns false for a non-resource with the same data" do
      fake_user = stub(:data => { :id => 1, :fullname => "Lindsay Fünke" })
      user.should_not == fake_user
    end

    it "delegates eql? to ==" do
      other = Object.new
      user.expects(:==).with(other).returns(true)
      user.eql?(other).should be_true
    end

    it "treats equal resources as equal for Array#uniq" do
      user2 = Foo::User.find(1)
      [user, user2].uniq.should == [user]
    end

    it "treats equal resources as equal for hash keys" do
      Foo::User.find(1)
      hash = { user => true }
      hash[Foo::User.find(1)] = false
      hash.size.should == 1
      hash.should == { user => false }
    end
  end
end
