# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe Her::Model::Attributes do
  context "mapping data to Ruby objects" do
    before { spawn_model "Foo::User" }

    it "handles new resource" do
      @new_user = Foo::User.new(fullname: "Tobias Fünke")
      expect(@new_user.new?).to be_truthy
      expect(@new_user.fullname).to eq("Tobias Fünke")
    end

    it "handles new resource with block" do
      @new_user = Foo::User.new do |user|
        user.fullname = "Tobias Fünke"
      end
      expect(@new_user.new?).to be_truthy
      expect(@new_user.fullname).to eq("Tobias Fünke")
    end

    it "accepts new resource with strings as hash keys" do
      @new_user = Foo::User.new("fullname" => "Tobias Fünke")
      expect(@new_user.fullname).to eq("Tobias Fünke")
    end

    it "handles method missing for getter" do
      @new_user = Foo::User.new(fullname: "Mayonegg")
      expect { @new_user.unknown_method_for_a_user }.to raise_error(NoMethodError)
      expect { @new_user.fullname }.not_to raise_error
    end

    it "handles method missing for setter" do
      @new_user = Foo::User.new
      expect { @new_user.fullname = "Tobias Fünke" }.not_to raise_error
    end

    it "handles method missing for query" do
      @new_user = Foo::User.new
      expect { @new_user.fullname? }.not_to raise_error
    end

    it "handles respond_to for getter" do
      @new_user = Foo::User.new(fullname: "Mayonegg")
      expect(@new_user).not_to respond_to(:unknown_method_for_a_user)
      expect(@new_user).to respond_to(:fullname)
    end

    it "handles respond_to for setter" do
      @new_user = Foo::User.new
      expect(@new_user).to respond_to(:fullname=)
    end

    it "handles respond_to for query" do
      @new_user = Foo::User.new
      expect(@new_user).to respond_to(:fullname?)
    end

    it "handles has_attribute? for getter" do
      @new_user = Foo::User.new(fullname: "Mayonegg")
      expect(@new_user).not_to have_attribute(:unknown_method_for_a_user)
      expect(@new_user).to have_attribute(:fullname)
    end

    it "handles get_attribute for getter" do
      @new_user = Foo::User.new(fullname: "Mayonegg")
      expect(@new_user.get_attribute(:unknown_method_for_a_user)).to be_nil
      expect(@new_user.get_attribute(:fullname)).to eq("Mayonegg")
    end

    it "handles get_attribute for getter with dash" do
      @new_user = Foo::User.new(:'life-span' => "3 years")
      expect(@new_user.get_attribute(:unknown_method_for_a_user)).to be_nil
      expect(@new_user.get_attribute(:'life-span')).to eq("3 years")
    end
  end

  context "assigning new resource data" do
    before do
      spawn_model "Foo::User"
      @user = Foo::User.new(active: false)
    end

    it "handles data update through #assign_attributes" do
      @user.assign_attributes active: true
      expect(@user).to be_active
    end
  end

  context "checking resource equality" do
    before do
      Her::API.setup url: "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { [200, {}, { id: 1, fullname: "Lindsay Fünke" }.to_json] }
          stub.get("/users/2") { [200, {}, { id: 1, fullname: "Tobias Fünke" }.to_json] }
          stub.get("/admins/1") { [200, {}, { id: 1, fullname: "Lindsay Fünke" }.to_json] }
        end
      end

      spawn_model "Foo::User"
      spawn_model "Foo::Admin"
    end

    let(:user) { Foo::User.find(1) }

    it "returns true for the exact same object" do
      expect(user).to eq(user)
    end

    it "returns true for the same resource via find" do
      expect(user).to eq(Foo::User.find(1))
    end

    it "returns true for the same class with identical data" do
      expect(user).to eq(Foo::User.new(id: 1, fullname: "Lindsay Fünke"))
    end

    it "returns true for a different resource with the same data" do
      expect(user).to eq(Foo::Admin.find(1))
    end

    it "returns false for the same class with different data" do
      expect(user).not_to eq(Foo::User.new(id: 2, fullname: "Tobias Fünke"))
    end

    it "returns false for a non-resource with the same data" do
      fake_user = double(data: { id: 1, fullname: "Lindsay Fünke" })
      expect(user).not_to eq(fake_user)
    end

    it "delegates eql? to ==" do
      other = Object.new
      expect(user).to receive(:==).with(other).and_return(true)
      expect(user.eql?(other)).to be_truthy
    end

    it "treats equal resources as equal for Array#uniq" do
      user2 = Foo::User.find(1)
      expect([user, user2].uniq).to eq([user])
    end

    it "treats equal resources as equal for hash keys" do
      Foo::User.find(1)
      hash = { user => true }
      hash[Foo::User.find(1)] = false
      expect(hash.size).to eq(1)
      expect(hash).to eq(user => false)
    end
  end

  context "handling metadata and errors" do
    before do
      Her::API.setup url: "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.adapter :test do |stub|
          stub.post("/users") { [200, {}, { id: 1, fullname: "Tobias Fünke" }.to_json] }
        end
      end

      spawn_model "Foo::User" do
        store_response_errors :errors
        store_metadata :my_data
      end

      @user = Foo::User.new(_errors: %w(Foo Bar), _metadata: { secret: true })
    end

    it "should return response_errors stored in the method provided by `store_response_errors`" do
      expect(@user.errors).to eq(%w(Foo Bar))
    end

    it "should remove the default method for errors" do
      expect { @user.response_errors }.to raise_error(NoMethodError)
    end

    it "should return metadata stored in the method provided by `store_metadata`" do
      expect(@user.my_data).to eq(secret: true)
    end

    it "should remove the default method for metadata" do
      expect { @user.metadata }.to raise_error(NoMethodError)
    end

    it "should work with #save" do
      @user.assign_attributes(fullname: "Tobias Fünke")
      @user.save
      expect { @user.metadata }.to raise_error(NoMethodError)
      expect(@user.my_data).to be_empty
      expect(@user.errors).to be_empty
    end
  end

  context "overwriting default attribute methods" do
    context "for getter method" do
      before do
        Her::API.setup url: "https://api.example.com" do |builder|
          builder.use Her::Middleware::FirstLevelParseJSON
          builder.adapter :test do |stub|
            stub.get("/users/1") { [200, {}, { id: 1, fullname: "Tobias Fünke", document: { url: "http://example.com" } }.to_json] }
          end
        end

        spawn_model "Foo::User" do
          def document
            @attributes[:document][:url]
          end
        end
      end

      it "bypasses Her's method" do
        @user = Foo::User.find(1)
        expect(@user.document).to eq("http://example.com")

        @user = Foo::User.find(1)
        expect(@user.document).to eq("http://example.com")
      end
    end

    context "for setter method" do
      before do
        Her::API.setup url: "https://api.example.com" do |builder|
          builder.use Her::Middleware::FirstLevelParseJSON
          builder.adapter :test do |stub|
            stub.get("/users/1") { [200, {}, { id: 1, fullname: "Tobias Fünke", document: { url: "http://example.com" } }.to_json] }
          end
        end

        spawn_model "Foo::User" do
          def document=(document)
            @attributes[:document] = document[:url]
          end
        end
      end

      it "bypasses Her's method" do
        @user = Foo::User.find(1)
        expect(@user.document).to eq("http://example.com")

        @user = Foo::User.find(1)
        expect(@user.document).to eq("http://example.com")
      end
    end

    context "for predicate method" do
      before do
        Her::API.setup url: "https://api.example.com" do |builder|
          builder.use Her::Middleware::FirstLevelParseJSON
          builder.adapter :test do |stub|
            stub.get("/users/1") { [200, {}, { id: 1, fullname: "Lindsay Fünke", document: { url: nil } }.to_json] }
            stub.get("/users/2") { [200, {}, { id: 1, fullname: "Tobias Fünke", document: { url: "http://example.com" } }.to_json] }
          end
        end

        spawn_model "Foo::User" do
          def document?
            document[:url].present?
          end
        end
      end

      it "byoasses Her's method" do
        @user = Foo::User.find(1)
        expect(@user.document?).to be_falsey

        @user = Foo::User.find(1)
        expect(@user.document?).to be_falsey

        @user = Foo::User.find(2)
        expect(@user.document?).to be_truthy
      end
    end
  end

  context "attributes class method" do
    before do
      spawn_model "Foo::User" do
        attributes :fullname, :document
      end
    end

    context "instance" do
      subject { Foo::User.new }

      it { is_expected.to respond_to(:fullname) }
      it { is_expected.to respond_to(:fullname=) }
      it { is_expected.to respond_to(:fullname?) }
    end

    it "defines setter that affects @attributes" do
      user = Foo::User.new
      user.fullname = "Tobias Fünke"
      expect(user.attributes[:fullname]).to eq("Tobias Fünke")
    end

    it "defines getter that reads @attributes" do
      user = Foo::User.new
      user.assign_attributes(fullname: "Tobias Fünke")
      expect(user.fullname).to eq("Tobias Fünke")
    end

    it "defines predicate that reads @attributes" do
      user = Foo::User.new
      expect(user.fullname?).to be_falsey
      user.assign_attributes(fullname: "Tobias Fünke")
      expect(user.fullname?).to be_truthy
    end

    context "when attribute methods are already defined" do
      before do
        class AbstractUser
          attr_accessor :fullname

          def fullname?
            @fullname.present?
          end
        end
        @spawned_models << :AbstractUser

        spawn_model "Foo::User", super_class: AbstractUser do
          attributes :fullname
        end
      end

      it "overrides getter method" do
        expect(Foo::User.generated_attribute_methods.instance_methods).to include(:fullname)
      end

      it "overrides setter method" do
        expect(Foo::User.generated_attribute_methods.instance_methods).to include(:fullname=)
      end

      it "overrides predicate method" do
        expect(Foo::User.generated_attribute_methods.instance_methods).to include(:fullname?)
      end

      it "defines setter that affects @attributes" do
        user = Foo::User.new
        user.fullname = "Tobias Fünke"
        expect(user.attributes[:fullname]).to eq("Tobias Fünke")
      end

      it "defines getter that reads @attributes" do
        user = Foo::User.new
        user.attributes[:fullname] = "Tobias Fünke"
        expect(user.fullname).to eq("Tobias Fünke")
      end

      it "defines predicate that reads @attributes" do
        user = Foo::User.new
        expect(user.fullname?).to be_falsey
        user.attributes[:fullname] = "Tobias Fünke"
        expect(user.fullname?).to be_truthy
      end
    end

    if ActiveModel::VERSION::MAJOR < 4
      it "creates a new mutex" do
        expect(Mutex).to receive(:new).once.and_call_original
        spawn_model "Foo::User" do
          attributes :fullname
        end
        expect(Foo::User.attribute_methods_mutex).not_to eq(Foo::User.generated_attribute_methods)
      end

      it "works well with Module#synchronize monkey patched by ActiveSupport" do
        Module.class_eval do
          def synchronize(*_args)
            raise "gotcha!"
          end
        end
        expect(Mutex).to receive(:new).once.and_call_original
        spawn_model "Foo::User" do
          attributes :fullname
        end
        expect(Foo::User.attribute_methods_mutex).not_to eq(Foo::User.generated_attribute_methods)
        Module.class_eval do
          undef :synchronize
        end
      end
    else
      it "uses ActiveModel's mutex" do
        expect(Foo::User.attribute_methods_mutex).to eq(Foo::User.generated_attribute_methods)
      end
    end

    it "uses a mutex" do
      spawn_model "Foo::User"
      expect(Foo::User.attribute_methods_mutex).to receive(:synchronize).once.and_call_original
      Foo::User.class_eval do
        attributes :fullname, :documents
      end
    end
  end
end
