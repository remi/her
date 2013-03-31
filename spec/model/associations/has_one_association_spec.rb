# encoding: utf-8
require File.join(File.dirname(__FILE__), "../../spec_helper.rb")

describe Her::Model::Associations do
  context "for has_one association" do
    describe :has_one do
      before do
        spawn_model 'Foo::User'
        Foo::User.has_one :category, category_options
        Foo::User.has_one :role, role_options
      end

      subject { Foo::User.associations }

      let(:category_options) { {} }
      let(:role_options) { {} }

      context "without additional options" do
        its([:has_one]) do
          should == [
            { :name => :category, :data_key => :category, :class_name => "Category", :path => "/category" },
            { :name => :role, :data_key => :role, :class_name => "Role", :path => "/role" }
          ]
        end
      end

      context "with additional options" do
        let(:category_options) { { :class_name => "Topic", :data_key => :topic } }

        its([:has_one]) do
          should == [
            { :name => :category, :data_key => :topic, :class_name => "Topic", :path => "/category" },
            { :name => :role, :data_key => :role, :class_name => "Role", :path => "/role" }
          ]
        end
      end

      describe "subclass associations" do
        let(:category_options) { { :class_name => "Topic", :data_key => :topic } }
        let(:subclass) { Class.new(Foo::User) }

        specify do
          subclass.associations.object_id.should_not == Foo::User.associations.object_id
          subclass.associations[:has_one].length.should == 2
          subclass.associations[:has_one].first[:class_name].should == "Topic"
        end
      end
    end

    describe :parse_associations do
      context "when association data is present" do
        context "without additional association options" do
          before do
            spawn_model('Foo::User') { has_one :role }
            spawn_model('Foo::Role')

            stub_api_for(Foo::User) do |stub|
              stub.get("/users/1") { |env| [200, {}, { :id => 1, :name => "Tobias Fünke", :role => { :id => 1, :name => "Admin" } }.to_json] }
            end

            stub_api_for(Foo::Role) do |stub|
              stub.get("/users/1/role") { |env| [200, {}, { :id => 2, :name => "Super Admin" }.to_json] }
            end
          end

          subject { Foo::User.find(1).role }
          its(:id) { should == 1 }
          its(:name) { should == "Admin" }

          context "when calling the association method with extra parameters" do
            subject { Foo::User.find(1).role(:pending => true) }
            its(:id) { should == 2 }
            its(:name) { should == "Super Admin" }
          end
        end

        context "with additional association options" do
          before do
            spawn_model('Foo::User') { has_one :role, :class_name => "UserRole", :data_key => :user_role }
            spawn_model('Foo::UserRole')

            stub_api_for(Foo::User) do |stub|
              stub.get("/users/1") { |env| [200, {}, { :id => 1, :name => "Tobias Fünke", :user_role => { :id => 1, :name => "Admin" } }.to_json] }
            end
          end

          subject { Foo::User.find(1).role }
          it { should be_kind_of Foo::UserRole }
          its(:id) { should == 1 }
          its(:name) { should == "Admin" }
        end
      end

      context "when association data is nil" do
        before do
          spawn_model('Foo::User') { has_one :role }

          stub_api_for(Foo::User) do |stub|
            stub.get("/users/1") { |env| [200, {}, { :id => 1, :name => "Tobias Fünke", :role => nil }.to_json] }
          end
        end

        subject { Foo::User.find(1).role }
        it { should be_nil }
      end
    end

    describe :fetch_association do
      context "without additional association options" do
        # TODO
      end

      context "with additional association options" do
        # TODO
      end
    end
  end
end
