# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe Her::Model::ORM do
  describe :ClassMethods do
    #--------------------------------------------------------------------------------------------
    # Her::Model::ORM::ClassMethods#find
    #--------------------------------------------------------------------------------------------
    describe :find do
      before { spawn_model 'Foo::User' }
      subject { Foo::User.find(find_arguments) }

      context "with a single scalar argument" do
        let(:find_arguments) { 1 }
        before do
          stub_api_for(Foo::User) do |stub|
            stub.get("/users/1") { |env| [200, {}, { :id => 1, :name => "Tobias Fünke" }.to_json] }
          end
        end

        its(:id) { should == 1 }
        its(:name) { should == "Tobias Fünke" }
      end

      context "with an array argument" do
        context "containing multiple elements" do
          let(:find_arguments) { [1,2] }
          before do
            stub_api_for(Foo::User) do |stub|
              stub.get("/users/1") { |env| [200, {}, { :id => 1, :name => "Tobias Fünke" }.to_json] }
              stub.get("/users/2") { |env| [200, {}, { :id => 1, :name => "Lindsay Fünke" }.to_json] }
            end
          end

          it { should be_kind_of(Array) }
          its(:length) { should == 2 }
        end

        context "containing a single element" do
          let(:find_arguments) { [1] }
          before do
            stub_api_for(Foo::User) do |stub|
              stub.get("/users/1") { |env| [200, {}, { :id => 1, :name => "Tobias Fünke" }.to_json] }
            end
          end

          it { should be_kind_of(Array) }
          its(:length) { should == 1 }
        end
      end
    end

    #--------------------------------------------------------------------------------------------
    # Her::Model::ORM::ClassMethods#all
    #--------------------------------------------------------------------------------------------
    describe :all do
      before do
        stub_api_for('Foo::AppUser') do |stub|
          stub.get("/app_users") { |env| [200, {}, [{ :id => 1, :name => "Tobias Fünke" }, { :id => 2, :name => "Lindsay Fünke" }].to_json] }
        end
      end

      subject { Foo::AppUser.all }

      its(:length) { should == 2 }

      describe "first element" do
        subject { Foo::AppUser.all.first }

        its(:id) { should == 1 }
        its(:name) { should == "Tobias Fünke" }
      end
    end

    #--------------------------------------------------------------------------------------------
    # Her::Model::ORM::ClassMethods#initialize
    #--------------------------------------------------------------------------------------------
    describe :new do
      describe "when first argument is present" do
        before { spawn_model 'Foo::User' }
        subject { Foo::User.new(new_arguments) }

        context "as a symbol-keys Hash" do
          let(:new_arguments) { { :fullname => "Tobias Fünke" } }
          it { should be_new }
          its(:id) { should be_nil }
          its(:fullname) { should == "Tobias Fünke" }
        end

        context "with string-keys Hash" do
          let(:new_arguments) { { "fullname" => "Tobias Fünke" } }
          it { should be_new }
          its(:id) { should be_nil }
          its(:fullname) { should == "Tobias Fünke" }
        end
      end
    end

    #--------------------------------------------------------------------------------------------
    # Her::Model::ORM::ClassMethods#create
    #--------------------------------------------------------------------------------------------
    describe :create do
      context "with successful response" do
        before do
          stub_api_for('Foo::User') do |stub|
            stub.post("/users") { |env| [200, {}, { :id => 1, :name => Faraday::Utils.parse_query(env[:body])['name'] }.to_json] }
          end
        end

        subject { Foo::User.create(:name => "Tobias Fünke") }
        its(:id) { should == 1 }
        its(:name) { should == "Tobias Fünke" }
      end

      context "with erroneous response" do
        before do
          stub_api_for('Foo::User') do |stub|
            stub.post("/users") { |env| [400, {}, { :errors => ['Name is required'] }.to_json] }
          end
        end

        subject { Foo::User.create }
        its(:id) { should be_nil }
        its(:response_errors) { should == ['Name is required'] }
      end
    end

    #--------------------------------------------------------------------------------------------
    # Her::Model::ORM::ClassMethods#save_existing
    #--------------------------------------------------------------------------------------------
    describe :save_existing do
      context "with successful response" do
        before do
          stub_api_for('Foo::User') do |stub|
            stub.put("/users/1") { |env| [200, {}, { :id => 1, :fullname => Faraday::Utils.parse_query(env[:body])['name'] }.to_json] }
          end
        end

        subject { Foo::User.save_existing(1, :name => "Lindsay Fünke") }
        its(:id) { should == 1 }
        its(:name) { should == "Lindsay Fünke" }
      end

      context "with erroneous response" do
        before do
          stub_api_for('Foo::User') do |stub|
            stub.put("/users/1") { |env| [400, {}, { :errors => ['Name is invalid'] }.to_json] }
          end
        end

        subject { Foo::User.save_existing(1, :name => "Lindsay Fünke") }
        its(:id) { should == 1 }
        its(:name) { should == "Lindsay Fünke" }
        its(:response_errors) { should == ['Name is invalid'] }
      end
    end

    #--------------------------------------------------------------------------------------------
    # Her::Model::ORM::ClassMethods#destroy_existing
    #--------------------------------------------------------------------------------------------
    describe :destroy_existing do
      before do
        stub_api_for('Foo::User') do |stub|
          stub.delete("/users/1") { |env| [200, {}, { :id => 1, :fullname => "Lindsay Fünke", :active => false }.to_json] }
        end
      end

      subject { Foo::User.destroy_existing(1) }

      it { should be_destroyed }
      it { should_not be_active }
      its(:id) { should == 1 }
      its(:fullname) { should == "Lindsay Fünke" }
    end

    #--------------------------------------------------------------------------------------------
    # Her::Model::ORM::ClassMethods#method_missing
    #--------------------------------------------------------------------------------------------
    describe :method_missing do
      before { spawn_model 'Foo::User' }

      describe "with getter method" do
        subject { Foo::User.new(:fullname => 'Mayonegg') }

        specify do
          expect { subject.unknown_method_for_a_user }.to raise_error(NoMethodError)
          expect { subject.fullname }.to_not raise_error(NoMethodError)
        end
      end

      describe "with setter method" do
        subject { Foo::User.new }

        specify do
          expect { subject.fullname = "Tobias Fünke" }.to_not raise_error(NoMethodError)
        end
      end

      describe "with query method" do
        subject { Foo::User.new }

        specify do
          expect { subject.fullname? }.to_not raise_error(NoMethodError)
        end
      end
    end

    #--------------------------------------------------------------------------------------------
    # Her::Model::ORM::ClassMethods#respond_to?
    #--------------------------------------------------------------------------------------------
    describe :respond_to? do
      before { spawn_model 'Foo::User' }

      describe "with getter method" do
        subject { Foo::User.new(:fullname => 'Mayonegg') }

        it { should respond_to(:fullname) }
        it { should_not respond_to(:unknown_method_for_a_user) }
      end

      describe "with setter method" do
        subject { Foo::User.new }
        it { should respond_to(:fullname=) }
      end

      describe "with query method" do
        subject { Foo::User.new }
        it { should respond_to(:fullname?) }
      end
    end

    #--------------------------------------------------------------------------------------------
    # Her::Model::ORM::ClassMethods#has_attribute?
    #--------------------------------------------------------------------------------------------
    describe :has_attribute? do
      before { spawn_model 'Foo::User' }
      subject { Foo::User.new(:fullname => 'Mayonegg') }

      it { should_not have_attribute(:unknown_method_for_a_user) }
      it { should have_attribute(:fullname) }
    end

    #--------------------------------------------------------------------------------------------
    # Her::Model::ORM::ClassMethods#get_attribute
    #--------------------------------------------------------------------------------------------
    describe :get_attribute do
      before { spawn_model 'Foo::User' }
      subject { Foo::User.new(:fullname => 'Mayonegg') }

      specify do
        subject.get_attribute(:unknown_method_for_a_user).should be_nil
        subject.get_attribute(:fullname).should == 'Mayonegg'
      end
    end

    #--------------------------------------------------------------------------------------------
    # Her::Model::ORM::ClassMethods#include_root_in_json
    #--------------------------------------------------------------------------------------------
    describe :include_root_in_json do
      context "when set to true" do
        before do
          spawn_model 'Foo::User' do
            include_root_in_json true
          end
        end

        subject { Foo::User.new(:fullname => "Tobias Fünke") }

        its(:to_params) { should == { 'user' => { :fullname => "Tobias Fünke" } } }
      end

      context "when set to another value" do
        before do
          spawn_model 'Foo::User' do
            include_root_in_json :person
          end
        end

        subject { Foo::User.new(:fullname => "Tobias Fünke") }

        its(:to_params) { should == { :person => { :fullname => "Tobias Fünke" } } }
      end
    end

    #--------------------------------------------------------------------------------------------
    # Her::Model::ORM::ClassMethods#parse_root_in_json
    #--------------------------------------------------------------------------------------------
    describe :parse_root_in_json do
      context "when set to true" do
        before do
          spawn_model('Foo::User') { parse_root_in_json true }
          stub_api_for(Foo::User) do |stub|
            stub.get("/users/1") { |env| [200, {}, { :user => { :id => 1, :name => "Tobias Fünke" } }.to_json] }
          end
        end

        subject { Foo::User.find(1) }
        its(:id) { should == 1 }
        its(:name) { should == "Tobias Fünke" }
      end

      context "when set to true" do
        before do
          spawn_model('Foo::User') { parse_root_in_json :person }
          stub_api_for(Foo::User) do |stub|
            stub.get("/users/1") { |env| [200, {}, { :person => { :id => 1, :name => "Tobias Fünke" } }.to_json] }
          end
        end

        subject { Foo::User.find(1) }
        its(:id) { should == 1 }
        its(:name) { should == "Tobias Fünke" }
      end
    end
  end

  describe :ModuleMethods do
    #--------------------------------------------------------------------------------------------
    # Her::Model::ORM::ModuleMethods#use_setter_methods
    #--------------------------------------------------------------------------------------------
    describe :use_setter_methods do
      before do
        spawn_model 'Foo::User' do
          def friends=(val)
            val = val.gsub("\r", "").split("\n").map { |friend| friend.gsub(/^\s*\*\s*/, "") } if val and val.is_a?(String)
            self.attributes[:friends] = val
          end

          def friends
            self.attributes[:friends].map { |friend| "* #{friend}" }.join("\n")
          end
        end

        stub_api_for(Foo::User) do |stub|
          stub.get("/users/1") { |env| [200, {}, { :id => 1, :friends => ["Maeby", "GOB", "Anne"] }.to_json] }
        end
      end

      context "with fetched resource" do
        subject { Foo::User.find(1) }
        its(:friends) { should == "* Maeby\n* GOB\n* Anne" }
        specify { subject.attributes[:friends].should == ["Maeby", "GOB", "Anne"] }
      end

      context "handles custom getters" do
        subject do
          Foo::User.new.tap { |user| user.friends = "* George\n* Oscar\n* Lucille" }
        end

        its(:friends) { should == "* George\n* Oscar\n* Lucille" }
        specify { subject.attributes[:friends].should == ["George", "Oscar", "Lucille"] }
      end
    end
  end

  describe :InstanceMethods do
    #--------------------------------------------------------------------------------------------
    # Her::Model::ORM::InstanceMethods#save
    #--------------------------------------------------------------------------------------------
    describe :save do
      before { spawn_model 'Foo::User' }

      context "with new resource" do
        context "with successful response" do
          before do
          end

          subject { Foo::User.new(:name => "Tobias Fünke") }

          context "with default to_params" do
            before do
              spawn_model 'Foo::User'
              stub_api_for(Foo::User) do |stub|
                stub.post("/users") { |env| [200, {}, { :id => 1, :name => Faraday::Utils.parse_query(env[:body])['name'], :occupation => "Doctor" }.to_json] }
              end

              subject.save
            end

            its(:id) { should == 1 }
            its(:name) { should == "Tobias Fünke" }
            its(:occupation) { should == "Doctor" }
          end

          context "with custom to_params" do
            before do
              spawn_model 'Foo::User' do
                def to_params
                  { :name => self.attributes[:name]+" Junior" }
                end
              end

              stub_api_for(Foo::User) do |stub|
                stub.post("/users") { |env| [200, {}, { :id => 1, :name => Faraday::Utils.parse_query(env[:body])['name'], :occupation => "Doctor" }.to_json] }
              end

              subject.save
            end

            its(:id) { should == 1 }
            its(:name) { should == "Tobias Fünke Junior" }
            its(:occupation) { should == "Doctor" }
          end
        end

        context "with erroneous response" do
          before do
            stub_api_for(Foo::User) do |stub|
              stub.post("/users") { |env| [400, {}, { :errors => ['Name is invalid'] }.to_json] }
            end
          end

          let(:user) { Foo::User.new(:name => "Tobias Fünke") }
          subject { user.save }
          it { should be_false }

          describe "resource" do
            subject { user }
            its(:id) { should be_nil }
            its(:name) { should == "Tobias Fünke" }
          end
        end
      end

      context "with existing resource" do
        context "with successful response" do
          before do
            stub_api_for(Foo::User) do |stub|
              stub.get("/users/1") { |env| [200, {}, { :id => 1, :name => "Tobias Fünke" }.to_json] }
              stub.put("/users/1") { |env| [200, {}, { :id => 1, :name => Faraday::Utils.parse_query(env[:body])['name'], :occupation => "Doctor" }.to_json] }
            end

            subject.name = "Lindsay Fünke"
            subject.save
          end

          subject { Foo::User.find(1) }

          its(:id) { should == 1 }
          its(:name) { should == "Lindsay Fünke" }
          its(:occupation) { should == "Doctor" }
        end

        context "with erroneous response" do
          before do
            stub_api_for(Foo::User) do |stub|
              stub.get("/users/1") { |env| [200, {}, { :id => 1, :name => "Tobias Fünke" }.to_json] }
              stub.put("/users/1") { |env| [400, {}, { :errors => ['Name is invalid'] }.to_json] }
            end
          end

          let(:user) { Foo::User.find(1) }
          subject { user.save }
          it { should be_false }

          describe "resource" do
            subject { user }
            its(:id) { should == 1 }
            its(:name) { should == "Tobias Fünke" }
          end
        end
      end
    end

    #--------------------------------------------------------------------------------------------
    # Her::Model::ORM::InstanceMethods#destroy
    #--------------------------------------------------------------------------------------------
    describe :destroy do
      before do
        stub_api_for('Foo::User') do |stub|
          stub.get("/users/1") { |env| [200, {}, { :id => 1, :fullname => "Lindsay Fünke", :active => true }.to_json] }
          stub.delete("/users/1") { |env| [200, {}, { :id => 1, :fullname => "Lindsay Fünke", :active => false }.to_json] }
        end

        subject.destroy
      end

      subject { Foo::User.find(1) }

      it { should be_destroyed }
      it { should_not be_active }
      its(:id) { should == 1 }
      its(:fullname) { should == "Lindsay Fünke" }
    end

    #--------------------------------------------------------------------------------------------
    # Her::Model::ORM::InstanceMethods#assign_attributes
    #--------------------------------------------------------------------------------------------
    describe :assign_attributes do
      before do
        spawn_model 'Foo::User'
        subject.assign_attributes(:active => true)
      end

      subject { Foo::User.new(:active => false) }
      it { should be_active }
    end

    #--------------------------------------------------------------------------------------------
    # Her::Model::ORM::InstanceMethods#==
    #--------------------------------------------------------------------------------------------
    describe :== do
      before do
        stub_api_for('Foo::User') do |stub|
          stub.get("/users/1") { |env| [200, {}, { :id => 1, :fullname => "Lindsay Fünke" }.to_json] }
          stub.get("/users/2") { |env| [200, {}, { :id => 1, :fullname => "Tobias Fünke" }.to_json] }
        end

        stub_api_for('Foo::Admin') do |stub|
          stub.get("/admins/1") { |env| [200, {}, { :id => 1, :fullname => "Lindsay Fünke" }.to_json] }
        end
      end

      let(:user) { Foo::User.find(1) }
      subject { user }

      it { should == user }
      it { should == Foo::User.find(1) }
      it { should == Foo::User.new(:id => 1, :fullname => "Lindsay Fünke") }
      it { should == Foo::Admin.find(1) }
      it { should_not == Foo::User.new(:id => 2, :fullname => "Tobias Fünke") }
      it { should_not == stub(:data => { :id => 1, :fullname => "Lindsay Fünke" }) }

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
        hash = { user => true }
        hash[Foo::User.find(1)] = false
        hash.size.should == 1
        hash.should == { user => false }
      end
    end
  end
end
