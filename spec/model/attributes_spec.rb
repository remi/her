# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe Her::Model::Attributes do
  context "mapping data to Ruby objects" do
    before { spawn_model "Foo::User" }

    it "handles new resource" do
      @new_user = Foo::User.new(:fullname => "Tobias Fünke")
      @new_user.new?.should be_truthy
      @new_user.fullname.should == "Tobias Fünke"
    end

    it "accepts new resource with strings as hash keys" do
      @new_user = Foo::User.new('fullname' => "Tobias Fünke")
      @new_user.fullname.should == "Tobias Fünke"
    end

    it "handles method missing for getter" do
      @new_user = Foo::User.new(:fullname => 'Mayonegg')
      expect { @new_user.unknown_method_for_a_user }.to raise_error(NoMethodError)
      expect { @new_user.fullname }.not_to raise_error()
    end

    it "handles method missing for setter" do
      @new_user = Foo::User.new
      expect { @new_user.fullname = "Tobias Fünke" }.not_to raise_error()
    end

    it "handles method missing for query" do
      @new_user = Foo::User.new
      expect { @new_user.fullname? }.not_to raise_error()
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

    it "handles has_attribute? for getter" do
      @new_user = Foo::User.new(:fullname => 'Mayonegg')
      @new_user.should_not have_attribute(:unknown_method_for_a_user)
      @new_user.should have_attribute(:fullname)
    end

    it "handles get_attribute for getter" do
      @new_user = Foo::User.new(:fullname => 'Mayonegg')
      @new_user.get_attribute(:unknown_method_for_a_user).should be_nil
      @new_user.get_attribute(:fullname).should == 'Mayonegg'
    end

    it "handles get_attribute for getter with dash" do
      @new_user = Foo::User.new(:'life-span' => '3 years')
      @new_user.get_attribute(:unknown_method_for_a_user).should be_nil
      @new_user.get_attribute(:'life-span').should == '3 years'
    end
  end


  context "assigning new resource data" do
    before do
      spawn_model "Foo::User"
      @user = Foo::User.new(:active => false)
    end

    it "handles data update through #assign_attributes" do
      @user.assign_attributes :active => true
      @user.should be_active
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
      fake_user = double(:data => { :id => 1, :fullname => "Lindsay Fünke" })
      user.should_not == fake_user
    end

    it "delegates eql? to ==" do
      other = Object.new
      user.should_receive(:==).with(other).and_return(true)
      user.eql?(other).should be_truthy
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

  context "handling metadata and errors" do
    before do
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.adapter :test do |stub|
          stub.post("/users") { |env| [200, {}, { :id => 1, :fullname => "Tobias Fünke" }.to_json] }
        end
      end

      spawn_model 'Foo::User' do
        store_response_errors :errors
        store_metadata :my_data
      end

      @user = Foo::User.new(:_errors => ["Foo", "Bar"], :_metadata => { :secret => true })
    end

    it "should return response_errors stored in the method provided by `store_response_errors`" do
      @user.errors.should == ["Foo", "Bar"]
    end

    it "should remove the default method for errors" do
      expect { @user.response_errors }.to raise_error(NoMethodError)
    end

    it "should return metadata stored in the method provided by `store_metadata`" do
      @user.my_data.should == { :secret => true }
    end

    it "should remove the default method for metadata" do
      expect { @user.metadata }.to raise_error(NoMethodError)
    end

    it "should work with #save" do
      @user.assign_attributes(:fullname => "Tobias Fünke")
      @user.save
      expect { @user.metadata }.to raise_error(NoMethodError)
      @user.my_data.should be_empty
      @user.errors.should be_empty
    end
  end

  context "overwriting default attribute methods" do
    context "for getter method" do
      before do
        Her::API.setup :url => "https://api.example.com" do |builder|
          builder.use Her::Middleware::FirstLevelParseJSON
          builder.adapter :test do |stub|
            stub.get("/users/1") { |env| [200, {}, { :id => 1, :fullname => "Tobias Fünke", :document => { :url => "http://example.com" } }.to_json] }
          end
        end

        spawn_model 'Foo::User' do
          def document
            @attributes[:document][:url]
          end
        end
      end

      it "bypasses Her's method" do
        @user = Foo::User.find(1)
        @user.document.should == "http://example.com"

        @user = Foo::User.find(1)
        @user.document.should == "http://example.com"
      end
    end

    context "for setter method" do
      before do
        Her::API.setup :url => "https://api.example.com" do |builder|
          builder.use Her::Middleware::FirstLevelParseJSON
          builder.adapter :test do |stub|
            stub.get("/users/1") { |env| [200, {}, { :id => 1, :fullname => "Tobias Fünke", :document => { :url => "http://example.com" } }.to_json] }
          end
        end

        spawn_model 'Foo::User' do
          def document=(document)
            @attributes[:document] = document[:url]
          end
        end
      end

      it "bypasses Her's method" do
        @user = Foo::User.find(1)
        @user.document.should == "http://example.com"

        @user = Foo::User.find(1)
        @user.document.should == "http://example.com"
      end
    end

    context "for predicate method" do
      before do
        Her::API.setup :url => "https://api.example.com" do |builder|
          builder.use Her::Middleware::FirstLevelParseJSON
          builder.adapter :test do |stub|
            stub.get("/users/1") { |env| [200, {}, { :id => 1, :fullname => "Lindsay Fünke", :document => { :url => nil } }.to_json] }
            stub.get("/users/2") { |env| [200, {}, { :id => 1, :fullname => "Tobias Fünke", :document => { :url => "http://example.com" } }.to_json] }
          end
        end

        spawn_model 'Foo::User' do
          def document?
            document[:url].present?
          end
        end
      end

      it "byoasses Her's method" do
        @user = Foo::User.find(1)
        @user.document?.should be_falsey

        @user = Foo::User.find(1)
        @user.document?.should be_falsey

        @user = Foo::User.find(2)
        @user.document?.should be_truthy
      end
    end
  end

  context "attributes class method" do
    before do
      spawn_model 'Foo::User' do
        attributes :fullname, :document
      end
    end

    context "instance" do
      subject { Foo::User.new }

      it { should respond_to(:fullname) }
      it { should respond_to(:fullname=) }
      it { should respond_to(:fullname?) }
    end

    it "defines setter that affects @attributes" do
      user = Foo::User.new
      user.fullname = 'Tobias Fünke'
      user.attributes[:fullname].should eq('Tobias Fünke')
    end

    it "defines getter that reads @attributes" do
      user = Foo::User.new
      user.assign_attributes(fullname: 'Tobias Fünke')
      user.fullname.should eq('Tobias Fünke')
    end

    it "defines predicate that reads @attributes" do
      user = Foo::User.new
      user.fullname?.should be_falsey
      user.assign_attributes(fullname: 'Tobias Fünke')
      user.fullname?.should be_truthy
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

        spawn_model 'Foo::User', super_class: AbstractUser do
          attributes :fullname
        end
      end

      it "overrides getter method" do
        Foo::User.generated_attribute_methods.instance_methods.should include(:fullname)
      end

      it "overrides setter method" do
        Foo::User.generated_attribute_methods.instance_methods.should include(:fullname=)
      end

      it "overrides predicate method" do
        Foo::User.generated_attribute_methods.instance_methods.should include(:fullname?)
      end

      it "defines setter that affects @attributes" do
        user = Foo::User.new
        user.fullname = 'Tobias Fünke'
        user.attributes[:fullname].should eq('Tobias Fünke')
      end

      it "defines getter that reads @attributes" do
        user = Foo::User.new
        user.attributes[:fullname] = 'Tobias Fünke'
        user.fullname.should eq('Tobias Fünke')
      end

      it "defines predicate that reads @attributes" do
        user = Foo::User.new
        user.fullname?.should be_falsey
        user.attributes[:fullname] = 'Tobias Fünke'
        user.fullname?.should be_truthy
      end
    end

    if ActiveModel::VERSION::MAJOR < 4
      it "creates a new mutex" do
        expect(Mutex).to receive(:new).once.and_call_original
        spawn_model 'Foo::User' do
          attributes :fullname
        end
        Foo::User.attribute_methods_mutex.should_not eq(Foo::User.generated_attribute_methods)
      end

      it "works well with Module#synchronize monkey patched by ActiveSupport" do
        Module.class_eval do
          def synchronize(*args)
            raise 'gotcha!'
          end
        end
        expect(Mutex).to receive(:new).once.and_call_original
        spawn_model 'Foo::User' do
          attributes :fullname
        end
        Foo::User.attribute_methods_mutex.should_not eq(Foo::User.generated_attribute_methods)
        Module.class_eval do
          undef :synchronize
        end
      end
    else
      it "uses ActiveModel's mutex" do
        Foo::User.attribute_methods_mutex.should eq(Foo::User.generated_attribute_methods)
      end
    end

    it "uses a mutex" do
      spawn_model 'Foo::User'
      expect(Foo::User.attribute_methods_mutex).to receive(:synchronize).once.and_call_original
      Foo::User.class_eval do
        attributes :fullname, :documents
      end
    end
  end
end
