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
          stub.get("/admin_users") { |env| [200, {}, [{ :admin_id => 1, :name => "Tobias Fünke" }, { :admin_id => 2, :name => "Lindsay Fünke" }].to_json] }
          stub.get("/admin_users/1") { |env| [200, {}, { :admin_id => 1, :name => "Tobias Fünke" }.to_json] }
        end
      end

      spawn_model "Foo::User" do
        uses_api api
      end

      spawn_model "Foo::AdminUser" do
        uses_api api
        primary_key :admin_id
      end
    end

    it "maps a single resource to a Ruby object" do
      @user = Foo::User.find(1)
      @user.id.should == 1
      @user.name.should == "Tobias Fünke"

      @admin = Foo::AdminUser.find(1)
      @admin.id.should == 1
      @admin.name.should == "Tobias Fünke"
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

    it 'handles new resource with custom primary key' do
      @new_user = Foo::AdminUser.new(:fullname => 'Lindsay Fünke', :id => -1)
      @new_user.should be_new

      @existing_user = Foo::AdminUser.find(1)
      @existing_user.should_not be_new
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
          stub.post("/users") { |env| [200, {}, { :data => { :name => "George Michael Bluth" }, :metadata => { :foo => "bar" }, :errors => { :title => ["should not be blank"] } }.to_json] }
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
      @user.response_errors.should == { :title => ["should not be blank"] }
    end

    it "adds resource errors to base" do
      @user = User.create(:name => "George Michael Bluth")
      @user.errors.full_messages.should == ["Title should not be blank"]
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
          stub.get("/users/2") { |env| [200, {}, { :id => 1 }.to_json] }
        end
      end

      spawn_model :User do
        uses_api api
        belongs_to :organization

        def friends=(val)
          val = val.gsub("\r", "").split("\n").map { |friend| friend.gsub(/^\s*\*\s*/, "") } if val and val.is_a?(String)
          @attributes[:friends] = val
        end

        def friends
          @attributes[:friends].map { |friend| "* #{friend}" }.join("\n")
        end
      end
    end

    it "handles custom setters" do
      @user = User.find(1)
      @user.friends.should == "* Maeby\n* GOB\n* Anne"
      @user.instance_eval do
        @attributes[:friends] = ["Maeby", "GOB", "Anne"]
      end
    end

    it "handles custom getters" do
      @user = User.new
      @user.friends = "* George\n* Oscar\n* Lucille"
      @user.friends.should == "* George\n* Oscar\n* Lucille"
      @user.instance_eval do
        @attributes[:friends] = ["George", "Oscar", "Lucille"]
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
          stub.get("/users?age=42&foo=bar") { |env| [200, {}, [{ :id => 3, :age => 42 }].to_json] }
          stub.get("/users?age=42") { |env| [200, {}, [{ :id => 1, :age => 42 }].to_json] }
          stub.get("/users?age=40") { |env| [200, {}, [{ :id => 1, :age => 40 }].to_json] }
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
      @users = User.where(:age => 42, :foo => "bar").all
      @users.should be_kind_of(Array)
      @users.first.id.should == 3
    end

    it "handles finding with other parameters and scoped" do
      @users = User.scoped
      @users.where(:age => 42).should be_all { |u| u.age == 42 }
      @users.where(:age => 40).should be_all { |u| u.age == 40 }
    end
  end

  context "building resources" do
    context "when request_new_object_on_build is not set (default)" do
      before do
        spawn_model("Foo::User")
      end

      it "builds a new resource without requesting it" do
        Foo::User.should_not_receive(:request)
        @new_user = Foo::User.build(:fullname => "Tobias Fünke")
        @new_user.new?.should be_true
        @new_user.fullname.should == "Tobias Fünke"
      end
    end

    context "when request_new_object_on_build is set" do
      before do
        Her::API.setup :url => "https://api.example.com" do |builder|
          builder.use Her::Middleware::FirstLevelParseJSON
          builder.use Faraday::Request::UrlEncoded
          builder.adapter :test do |stub|
            stub.get("/users/new") { |env| ok! :id => nil, :fullname => params(env)[:fullname], :email => "tobias@bluthcompany.com" }
          end
        end

        spawn_model("Foo::User") { request_new_object_on_build true }
      end

      it "requests a new resource" do
        Foo::User.should_receive(:request).once.and_call_original
        @new_user = Foo::User.build(:fullname => "Tobias Fünke")
        @new_user.new?.should be_true
        @new_user.fullname.should == "Tobias Fünke"
        @new_user.email.should == "tobias@bluthcompany.com"
      end
    end
  end

  context "creating resources" do
    before do
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.post("/users") { |env| [200, {}, { :id => 1, :fullname => Faraday::Utils.parse_query(env[:body])['fullname'], :email => Faraday::Utils.parse_query(env[:body])['email'] }.to_json] }
          stub.post("/companies") { |env| [200, {}, { :errors =>{ :name => ["is required"] } }.to_json] }
        end
      end

      spawn_model "Foo::User"
      spawn_model "Foo::Company"
    end

    it "handle one-line resource creation" do
      @user = Foo::User.create(:fullname => "Tobias Fünke", :email => "tobias@bluth.com")
      @user.id.should == 1
      @user.fullname.should == "Tobias Fünke"
      @user.email.should == "tobias@bluth.com"
    end

    it "handle resource creation through Model.new + #save" do
      @user = Foo::User.new(:fullname => "Tobias Fünke")
      @user.save.should be_true
      @user.fullname.should == "Tobias Fünke"
    end

    it "handle resource creation through Model.new + #save!" do
      @user = Foo::User.new(:fullname => "Tobias Fünke")
      @user.save!.should be_true
      @user.fullname.should == "Tobias Fünke"
    end

    it "returns false when #save gets errors" do
      @company = Foo::Company.new
      @company.save.should be_false
    end

    it "raises ResourceInvalid when #save! gets errors" do
      @company = Foo::Company.new
      expect { @company.save! }.to raise_error Her::Errors::ResourceInvalid, "Remote validation failed: Name is required"
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
      @user.should be_destroyed
    end

    it "handle resource deletion through #destroy on an existing resource" do
      @user = Foo::User.find(1)
      @user.destroy
      @user.active.should be_false
      @user.should be_destroyed
    end
  end

  context 'customizing HTTP methods' do
    before do
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
      end
    end

    context 'create' do
      before do
        Her::API.default_api.connection.adapter :test do |stub|
          stub.put('/users') { |env| [200, {}, { :id => 1, :fullname => 'Tobias Fünke' }.to_json] }
        end
        spawn_model 'Foo::User' do
          attributes :fullname, :email
          method_for :create, 'PUT'
        end
      end

      context 'for top-level class' do
        it 'uses the custom method (PUT) instead of default method (POST)' do
          user = Foo::User.new(:fullname => 'Tobias Fünke')
          user.should be_new
          user.save.should be_true
        end
      end

      context 'for children class' do
        before do
          class User < Foo::User; end
          @spawned_models << :User
        end

        it 'uses the custom method (PUT) instead of default method (POST)' do
          user = User.new(:fullname => 'Tobias Fünke')
          user.should be_new
          user.save.should be_true
        end
      end
    end

    context 'update' do
      before do
        Her::API.default_api.connection.adapter :test do |stub|
          stub.get('/users/1') { |env| [200, {}, { :id => 1, :fullname => 'Lindsay Fünke' }.to_json] }
          stub.post('/users/1') { |env| [200, {}, { :id => 1, :fullname => 'Tobias Fünke' }.to_json] }
        end

        spawn_model 'Foo::User' do
          attributes :fullname, :email
          method_for :update, :post
        end
      end

      it 'uses the custom method (POST) instead of default method (PUT)' do
        user = Foo::User.find(1)
        user.fullname.should eq 'Lindsay Fünke'
        user.fullname = 'Toby Fünke'
        user.save
        user.fullname.should eq 'Tobias Fünke'
      end
    end
  end
end
