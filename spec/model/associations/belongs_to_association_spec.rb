# encoding: utf-8
require File.join(File.dirname(__FILE__), "../../spec_helper.rb")

describe Her::Model::Associations do
  context "for belongs_to association" do
    describe :belongs_to do
      before do
        spawn_model 'Foo::User'
        Foo::User.belongs_to :organization, organization_options
        Foo::User.belongs_to :family, family_options
      end

      subject { Foo::User.associations }

      let(:organization_options) { {} }
      let(:family_options) { {} }

      context "without additional details" do
        its([:belongs_to]) do
          should == [
            { :name => :organization, :data_key => :organization, :class_name => "Organization", :foreign_key => "organization_id", :path => "/organizations/:id" },
            { :name => :family, :data_key => :family, :class_name => "Family", :foreign_key => "family_id", :path => "/families/:id" }
          ]
        end
      end

      context "with additional details" do
        let(:organization_options) { { :class_name => "Business", :foreign_key => "org_id", :data_key => :org } }

        its([:belongs_to]) do
          should == [
            { :name => :organization, :data_key => :org, :class_name => "Business", :foreign_key => "org_id", :path => "/organizations/:id" },
            { :name => :family, :data_key => :family, :class_name => "Family", :foreign_key => "family_id", :path => "/families/:id" }
          ]
        end
      end

      describe "subclass associations" do
        let(:organization_options) { { :class_name => "Business", :foreign_key => "org_id", :data_key => :org } }
        let(:subclass) { Class.new(Foo::User) }

        specify do
          subclass.associations.object_id.should_not == Foo::User.associations.object_id
          subclass.associations[:belongs_to].length.should == 2
          subclass.associations[:belongs_to].first[:class_name].should == "Business"
        end
      end
    end

    describe :parse_associations do
      context "when association data is present" do
        context "without additional association options" do
          before do
            spawn_model('Foo::User') { belongs_to :organization }
            spawn_model('Foo::Organization')

            stub_api_for(Foo::User) do |stub|
              stub.get("/users/1") { |env| [200, {}, { :id => 1, :name => "Tobias Fünke", :organization => { :id => 1, :name => "Bluth Company" }, :organization_id => 1 }.to_json] }
            end

            stub_api_for(Foo::Organization) do |stub|
              stub.get("/organizations/1") { |env| [200, {}, { :id => 2, :name => "Sitwell Enterprises" }.to_json] }
            end
          end

          subject { Foo::User.find(1).organization }
          its(:id) { should == 1 }
          its(:name) { should == "Bluth Company" }

          context "when calling the association method with extra parameters" do
            subject { Foo::User.find(1).organization(:pending => true) }
            its(:id) { should == 2 }
            its(:name) { should == "Sitwell Enterprises" }
          end
        end

        context "with additional association options" do
          before do
            spawn_model('Foo::User') { belongs_to :organization, :class_name => "Business", :data_key => :biz }
            spawn_model('Foo::Business')

            stub_api_for(Foo::User) do |stub|
              stub.get("/users/1") { |env| [200, {}, { :id => 1, :name => "Tobias Fünke", :biz => { :id => 1, :name => "Bluth Company" }, :organization_id => 1 }.to_json] }
            end
          end

          subject { Foo::User.find(1).organization }
          it { should be_kind_of(Foo::Business) }
          its(:id) { should == 1 }
          its(:name) { should == "Bluth Company" }
        end
      end

      context "when association data is nil" do
        context "for belongs_to association" do
          before do
            spawn_model('Foo::User') { belongs_to :organization }

            stub_api_for(Foo::User) do |stub|
              stub.get("/users/1") { |env| [200, {}, { :id => 1, :name => "Tobias Fünke", :organization => nil }.to_json] }
            end
          end

          subject { Foo::User.find(1).organization }
          it { should be_nil }
        end
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
