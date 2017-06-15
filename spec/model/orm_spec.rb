# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe Her::Model::ORM do
  context "mapping data to Ruby objects" do
    before do
      api = Her::API.new
      api.setup url: "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { [200, {}, { id: 1, name: "Tobias Fünke" }.to_json] }
          stub.get("/users") { [200, {}, [{ id: 1, name: "Tobias Fünke" }, { id: 2, name: "Lindsay Fünke" }].to_json] }
          stub.get("/admin_users") { [200, {}, [{ admin_id: 1, name: "Tobias Fünke" }, { admin_id: 2, name: "Lindsay Fünke" }].to_json] }
          stub.get("/admin_users/1") { [200, {}, { admin_id: 1, name: "Tobias Fünke" }.to_json] }
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
      expect(@user.id).to eq(1)
      expect(@user.name).to eq("Tobias Fünke")

      @admin = Foo::AdminUser.find(1)
      expect(@admin.id).to eq(1)
      expect(@admin.name).to eq("Tobias Fünke")
    end

    it "maps a collection of resources to an array of Ruby objects" do
      @users = Foo::User.all
      expect(@users.length).to eq(2)
      expect(@users.first.name).to eq("Tobias Fünke")

      @users = Foo::AdminUser.all
      expect(@users.length).to eq(2)
      expect(@users.first.name).to eq("Tobias Fünke")
    end

    it "handles new resource" do
      @new_user = Foo::User.new(fullname: "Tobias Fünke")
      expect(@new_user.new?).to be_truthy
      expect(@new_user.new_record?).to be_truthy
      expect(@new_user.fullname).to eq("Tobias Fünke")

      @existing_user = Foo::User.find(1)
      expect(@existing_user.new?).to be_falsey
      expect(@existing_user.new_record?).to be_falsey
    end

    it "handles new resource with custom primary key" do
      @new_user = Foo::AdminUser.new(fullname: "Lindsay Fünke", id: -1)
      expect(@new_user).to be_new

      @existing_user = Foo::AdminUser.find(1)
      expect(@existing_user).not_to be_new
    end
  end

  context "mapping data, metadata and error data to Ruby objects" do
    before do
      api = Her::API.new
      api.setup url: "https://api.example.com" do |builder|
        builder.use Her::Middleware::SecondLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users") { [200, {}, { data: [{ id: 1, name: "Tobias Fünke" }, { id: 2, name: "Lindsay Fünke" }], metadata: { total_pages: 10, next_page: 2 }, errors: %w(Oh My God) }.to_json] }
          stub.get("/users") { |env| [200, {}, { :data => [{ :id => 1, :name => "Tobias Fünke" }, { :id => 2, :name => "Lindsay Fünke" }], :metadata => { :total_pages => 10, :next_page => 2 }, :errors => ["Oh", "My", "God"] }.to_json] }
          stub.post("/users") { |env| [200, {}, { :data => { :name => "George Michael Bluth" }, :metadata => { :foo => "bar" }, :errors => ["Yes", "Sir"] }.to_json] }
          stub.delete("/users/1") { |env| [200, {}, { :data => { :id => 1 }, :metadata => { :foo => "bar" }, :errors => ["Yes", "Sir"] }.to_json] }
        end
      end

      spawn_model :User do
        uses_api api
      end
    end

    it "handles metadata on a collection" do
      @users = User.all
      expect(@users.metadata[:total_pages]).to eq(10)
    end

    it "handles error data on a collection" do
      @users = User.all
      expect(@users.errors.length).to eq(3)
    end

    it "handles metadata on a resource" do
      @user = User.create(name: "George Michael Bluth")
      expect(@user.metadata[:foo]).to eq("bar")
    end

    it "handles error data on a resource" do
      @user = User.create(name: "George Michael Bluth")
      expect(@user.response_errors).to eq(%w(Yes Sir))
    end

    it "handles metadata on a destroyed resource" do
      @user = User.destroy_existing(1)
      expect(@user.metadata[:foo]).to eq("bar")
    end

    it "handles error data on a destroyed resource" do
      @user = User.destroy_existing(1)
      expect(@user.response_errors).to eq(%w(Yes Sir))
    end
  end

  context "mapping data, metadata and error data in string keys to Ruby objects" do
    before do
      api = Her::API.new
      api.setup url: "https://api.example.com" do |builder|
        builder.use Her::Middleware::SecondLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users") { [200, {}, { data: [{ id: 1, name: "Tobias Fünke" }, { id: 2, name: "Lindsay Fünke" }], metadata: { total_pages: 10, next_page: 2 }, errors: %w(Oh My God) }.to_json] }
          stub.post("/users") { [200, {}, { data: { name: "George Michael Bluth" }, metadata: { foo: "bar" }, errors: %w(Yes Sir) }.to_json] }
        end
      end

      spawn_model :User do
        uses_api api
      end
    end

    it "handles metadata on a collection" do
      @users = User.all
      expect(@users.metadata[:total_pages]).to eq(10)
    end

    it "handles error data on a collection" do
      @users = User.all
      expect(@users.errors.length).to eq(3)
    end

    it "handles metadata on a resource" do
      @user = User.create(name: "George Michael Bluth")
      expect(@user.metadata[:foo]).to eq("bar")
    end

    it "handles error data on a resource" do
      @user = User.create(name: "George Michael Bluth")
      expect(@user.response_errors).to eq(%w(Yes Sir))
    end
  end

  context "defining custom getters and setters" do
    before do
      api = Her::API.new
      api.setup url: "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { [200, {}, { id: 1, friends: %w(Maeby GOB Anne) }.to_json] }
          stub.get("/users/2") { [200, {}, { id: 1 }.to_json] }
        end
      end

      spawn_model :User do
        uses_api api
        belongs_to :organization

        def friends=(val)
          val = val.delete("\r").split("\n").map { |friend| friend.gsub(/^\s*\*\s*/, "") } if val && val.is_a?(String)
          @attributes[:friends] = val
        end

        def friends
          @attributes[:friends].map { |friend| "* #{friend}" }.join("\n")
        end
      end
    end

    it "handles custom setters" do
      @user = User.find(1)
      expect(@user.friends).to eq("* Maeby\n* GOB\n* Anne")
      @user.instance_eval do
        @attributes[:friends] = %w(Maeby GOB Anne)
      end
    end

    it "handles custom getters" do
      @user = User.new
      @user.friends = "* George\n* Oscar\n* Lucille"
      expect(@user.friends).to eq("* George\n* Oscar\n* Lucille")
      @user.instance_eval do
        @attributes[:friends] = %w(George Oscar Lucille)
      end
    end
  end

  context "finding resources" do
    before do
      api = Her::API.new
      api.setup url: "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { [200, {}, { id: 1, age: 42 }.to_json] }
          stub.get("/users/2") { [200, {}, { id: 2, age: 34 }.to_json] }
          stub.get("/users?id[]=1&id[]=2") { [200, {}, [{ id: 1, age: 42 }, { id: 2, age: 34 }].to_json] }
          stub.get("/users?age=42&foo=bar") { [200, {}, [{ id: 3, age: 42 }].to_json] }
          stub.get("/users?age=42") { [200, {}, [{ id: 1, age: 42 }].to_json] }
          stub.get("/users?age=40") { [200, {}, [{ id: 1, age: 40 }].to_json] }
          stub.get("/users?name=baz") { [200, {}, [].to_json] }
          stub.post("/users") { [200, {}, { id: 5, name: "baz" }.to_json] }
        end
      end

      spawn_model :User do
        uses_api api
      end
    end

    it "handles finding by a single id" do
      @user = User.find(1)
      expect(@user.id).to eq(1)
    end

    it "handles finding by multiple ids" do
      @users = User.find(1, 2)
      expect(@users).to be_kind_of(Array)
      expect(@users.length).to eq(2)
      expect(@users[0].id).to eq(1)
      expect(@users[1].id).to eq(2)
    end

    it "handles finding by an array of ids" do
      @users = User.find([1, 2])
      expect(@users).to be_kind_of(Array)
      expect(@users.length).to eq(2)
      expect(@users[0].id).to eq(1)
      expect(@users[1].id).to eq(2)
    end

    it "handles finding by an array of ids of length 1" do
      @users = User.find([1])
      expect(@users).to be_kind_of(Array)
      expect(@users.length).to eq(1)
      expect(@users[0].id).to eq(1)
    end

    it "handles finding by an array id param of length 2" do
      @users = User.find(id: [1, 2])
      expect(@users).to be_kind_of(Array)
      expect(@users.length).to eq(2)
      expect(@users[0].id).to eq(1)
      expect(@users[1].id).to eq(2)
    end

    it "handles finding with id parameter as an array" do
      @users = User.where(id: [1, 2])
      expect(@users).to be_kind_of(Array)
      expect(@users.length).to eq(2)
      expect(@users[0].id).to eq(1)
      expect(@users[1].id).to eq(2)
    end

    it "handles finding by attributes" do
      @user = User.find_by(age: 42)
      expect(@user).to be_a(User)
      expect(@user.id).to eq(1)
    end

    it "handles find or create by attributes" do
      @user = User.find_or_create_by(name: "baz")
      expect(@user).to be_a(User)
      expect(@user.id).to eq(5)
    end

    it "handles find or initialize by attributes" do
      @user = User.find_or_initialize_by(name: "baz")
      expect(@user).to be_a(User)
      expect(@user).to_not be_persisted
    end

    it "handles finding with other parameters" do
      @users = User.where(age: 42, foo: "bar").all
      expect(@users).to be_kind_of(Array)
      expect(@users.first.id).to eq(3)
    end

    it "handles finding with other parameters and scoped" do
      @users = User.scoped
      expect(@users.where(age: 42)).to be_all { |u| u.age == 42 }
      expect(@users.where(age: 40)).to be_all { |u| u.age == 40 }
    end

    it "handles reloading a resource" do
      @user = User.find(1)
      @user.age = "Oops"
      @user.reload
      expect(@user.age).to eq 42
      expect(@user).to be_persisted
    end
  end

  context "building resources" do
    context "when request_new_object_on_build is not set (default)" do
      before do
        spawn_model("Foo::User")
      end

      it "builds a new resource without requesting it" do
        expect(Foo::User).not_to receive(:request)
        @new_user = Foo::User.build(fullname: "Tobias Fünke")
        expect(@new_user.new?).to be_truthy
        expect(@new_user.fullname).to eq("Tobias Fünke")
      end
    end

    context "when request_new_object_on_build is set" do
      before do
        Her::API.setup url: "https://api.example.com" do |builder|
          builder.use Her::Middleware::FirstLevelParseJSON
          builder.use Faraday::Request::UrlEncoded
          builder.adapter :test do |stub|
            stub.get("/users/new") { |env| ok! id: nil, fullname: params(env)[:fullname], email: "tobias@bluthcompany.com" }
          end
        end

        spawn_model("Foo::User") { request_new_object_on_build true }
      end

      it "requests a new resource" do
        expect(Foo::User).to receive(:request).once.and_call_original
        @new_user = Foo::User.build(fullname: "Tobias Fünke")
        expect(@new_user.new?).to be_truthy
        expect(@new_user.fullname).to eq("Tobias Fünke")
        expect(@new_user.email).to eq("tobias@bluthcompany.com")
      end
    end
  end

  context "creating resources" do
    before do
      Her::API.setup url: "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.post("/users") { |env| [200, {}, { id: 1, fullname: Faraday::Utils.parse_query(env[:body])["fullname"], email: Faraday::Utils.parse_query(env[:body])["email"] }.to_json] }
          stub.post("/companies") { [200, {}, { errors: ["name is required"] }.to_json] }
        end
      end

      spawn_model "Foo::User"
      spawn_model "Foo::Company"
    end

    it "handle one-line resource creation" do
      @user = Foo::User.create(fullname: "Tobias Fünke", email: "tobias@bluth.com")
      expect(@user.id).to eq(1)
      expect(@user.fullname).to eq("Tobias Fünke")
      expect(@user.email).to eq("tobias@bluth.com")
    end

    it "handle resource creation through Model.new + #save" do
      @user = Foo::User.new(fullname: "Tobias Fünke")
      expect(@user.save).to be_truthy
      expect(@user.fullname).to eq("Tobias Fünke")
    end

    it "handle resource creation through Model.new + #save!" do
      @user = Foo::User.new(fullname: "Tobias Fünke")
      expect(@user.save!).to be_truthy
      expect(@user.fullname).to eq("Tobias Fünke")
    end

    it "returns false when #save gets errors" do
      @company = Foo::Company.new
      expect(@company.save).to be_falsey
    end

    it "raises ResourceInvalid when #save! gets errors" do
      @company = Foo::Company.new
      expect { @company.save! }.to raise_error Her::Errors::ResourceInvalid, "Remote validation failed: name is required"
    end

    it "don't overwrite data if response is empty" do
      @company = Foo::Company.new(name: "Company Inc.")
      expect(@company.save).to be_falsey
      expect(@company.name).to eq("Company Inc.")
    end
  end

  context "updating resources" do
    before do
      Her::API.setup url: "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { [200, {}, { id: 1, fullname: "Tobias Fünke", admin: false }.to_json] }
          stub.put("/users/1") { [200, {}, { id: 1, fullname: "Lindsay Fünke", admin: true }.to_json] }
          stub.get("/pages/1") { [200, {}, { id: 1, views: 1, unique_visitors: 4 }.to_json] }
          stub.put("/pages/1") { [200, {}, { id: 1, views: 2, unique_visitors: 3 }.to_json] }
        end
      end

      spawn_model "Foo::User"
      spawn_model "Foo::Page"
    end

    it "handle resource data update without saving it" do
      @user = Foo::User.find(1)
      expect(@user.fullname).to eq("Tobias Fünke")
      @user.fullname = "Kittie Sanchez"
      expect(@user.fullname).to eq("Kittie Sanchez")
    end

    it "handle resource update through the .update class method" do
      @user = Foo::User.save_existing(1, fullname: "Lindsay Fünke")
      expect(@user.fullname).to eq("Lindsay Fünke")
    end

    it "handle resource update through #save on an existing resource" do
      @user = Foo::User.find(1)
      @user.fullname = "Lindsay Fünke"
      @user.save
      expect(@user.fullname).to eq("Lindsay Fünke")
    end

    it "handles resource update through #toggle without saving it" do
      @user = Foo::User.find(1)
      expect(@user.admin).to be_falsey
      expect(@user).to_not receive(:save)
      @user.toggle(:admin)
      expect(@user.admin).to be_truthy
    end

    it "handles resource update through #toggle!" do
      @user = Foo::User.find(1)
      expect(@user.admin).to be_falsey
      expect(@user).to receive(:save).and_return(true)
      @user.toggle!(:admin)
      expect(@user.admin).to be_truthy
    end

    it "handles resource update through #increment without saving it" do
      page = Foo::Page.find(1)
      expect(page.views).to be 1
      expect(page).to_not receive(:save)
      page.increment(:views)
      expect(page.views).to be 2
      page.increment(:views, 2)
      expect(page.views).to be 4
    end

    it "handles resource update through #increment!" do
      page = Foo::Page.find(1)
      expect(page.views).to be 1
      expect(page).to receive(:save).and_return(true)
      page.increment!(:views)
      expect(page.views).to be 2
    end

    it "handles resource update through #decrement without saving it" do
      page = Foo::Page.find(1)
      expect(page.unique_visitors).to be 4
      expect(page).to_not receive(:save)
      page.decrement(:unique_visitors)
      expect(page.unique_visitors).to be 3
      page.decrement(:unique_visitors, 2)
      expect(page.unique_visitors).to be 1
    end

    it "handles resource update through #decrement!" do
      page = Foo::Page.find(1)
      expect(page.unique_visitors).to be 4
      expect(page).to receive(:save).and_return(true)
      page.decrement!(:unique_visitors)
      expect(page.unique_visitors).to be 3
    end
  end

  context "deleting resources" do
    let(:status) { 200 }
    before do
      Her::API.setup url: "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { [200, {}, { id: 1, fullname: "Tobias Fünke", active: true }.to_json] }
          stub.delete("/users/1") { [status, {}, { id: 1, fullname: "Lindsay Fünke", active: false }.to_json] }
        end
      end

      spawn_model "Foo::User"
    end

    it "handle resource deletion through the .destroy class method" do
      @user = Foo::User.destroy_existing(1)
      expect(@user.active).to be_falsey
      expect(@user).to be_destroyed
    end

    it "handle resource deletion through #destroy on an existing resource" do
      @user = Foo::User.find(1)
      @user.destroy
      expect(@user.active).to be_falsey
      expect(@user).to be_destroyed
    end

    context "with response_errors" do
      let(:status) { 422 }
      it "set user.destroyed to false if errors are present through the .destroy class method" do
        @user = Foo::User.destroy_existing(1)
        expect(@user).not_to be_destroyed
      end

      it "set user.destroyed to false if errors are present through #destroy on an existing resource" do
        @user = Foo::User.find(1)
        @user.destroy
        expect(@user).not_to be_destroyed
      end
    end

    context "with params" do
      before do
        Her::API.setup url: "https://api.example.com" do |builder|
          builder.use Her::Middleware::FirstLevelParseJSON
          builder.use Faraday::Request::UrlEncoded
          builder.adapter :test do |stub|
            stub.delete("/users/1?delete_type=soft") { [200, {}, { id: 1, fullname: "Lindsay Fünke", active: false }.to_json] }
          end
        end
      end

      it "handle resource deletion through the .destroy class method" do
        @user = Foo::User.destroy_existing(1, delete_type: "soft")
        expect(@user.active).to be_falsey
        expect(@user).to be_destroyed
      end

      it "handle resource deletion through #destroy on an existing resource" do
        @user = Foo::User.find(1)
        @user.destroy(delete_type: "soft")
        expect(@user.active).to be_falsey
        expect(@user).to be_destroyed
      end
    end
  end

  context "customizing HTTP methods" do
    before do
      Her::API.setup url: "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
      end
    end

    context "create" do
      before do
        Her::API.default_api.connection.adapter :test do |stub|
          stub.put("/users") { [200, {}, { id: 1, fullname: "Tobias Fünke" }.to_json] }
        end
        spawn_model "Foo::User" do
          attributes :fullname, :email
          method_for :create, "PUT"
        end
      end

      context "for top-level class" do
        it "uses the custom method (PUT) instead of default method (POST)" do
          user = Foo::User.new(fullname: "Tobias Fünke")
          expect(user).to be_new
          expect(user.save).to be_truthy
        end
      end

      context "for children class" do
        before do
          class User < Foo::User; end
          @spawned_models << :User
        end

        it "uses the custom method (PUT) instead of default method (POST)" do
          user = User.new(fullname: "Tobias Fünke")
          expect(user).to be_new
          expect(user.save).to be_truthy
        end
      end
    end

    context "update" do
      before do
        Her::API.default_api.connection.adapter :test do |stub|
          stub.get("/users/1") { [200, {}, { id: 1, fullname: "Lindsay Fünke" }.to_json] }
          stub.post("/users/1") { [200, {}, { id: 1, fullname: "Tobias Fünke" }.to_json] }
        end

        spawn_model "Foo::User" do
          attributes :fullname, :email
          method_for :update, :post
        end
      end

      it "uses the custom method (POST) instead of default method (PUT)" do
        user = Foo::User.find(1)
        expect(user.fullname).to eq "Lindsay Fünke"
        user.fullname = "Toby Fünke"
        user.save
        expect(user.fullname).to eq "Tobias Fünke"
      end
    end
  end

  context "registering callbacks" do
    before do
      Her::API.setup url: "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { [200, {}, { id: 1, fullname: "Tobias Fünke" }.to_json] }
          stub.put("/users/1") { [200, {}, { id: 1, fullname: "Tobias Fünke" }.to_json] }
          stub.post("/users")  { [200, {}, { id: 2, fullname: "Lindsay Fünke" }.to_json] }
        end
      end

      spawn_model "User" do
        before_save :before_save_callback
        before_create :before_create_callback
        before_update :before_update_callback
        after_update :after_update_callback
        after_create :after_create_callback
        after_save :after_save_callback
        def before_save_callback; end
        def before_create_callback; end
        def before_update_callback; end
        def after_update_callback; end
        def after_create_callback; end
        def after_save_callback; end
      end
    end

    it "runs create callbacks in the correct order" do
      @user = User.new(fullname: "Tobias Fünke")
      expect(@user).to receive(:before_save_callback).ordered
      expect(@user).to receive(:before_create_callback).ordered
      expect(@user).to receive(:after_create_callback).ordered
      expect(@user).to receive(:after_save_callback).ordered
      @user.save
    end

    it "runs update callbacks in the correct order" do
      @user = User.find(1)
      expect(@user).to receive(:before_save_callback).ordered
      expect(@user).to receive(:before_update_callback).ordered
      expect(@user).to receive(:after_update_callback).ordered
      expect(@user).to receive(:after_save_callback).ordered
      @user.save
    end
  end
end
