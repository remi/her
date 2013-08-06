# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe Her::Model::HTTP do
  context "binding a model with an API" do
    let(:api1) { Her::API.new :url => "https://api1.example.com" }
    let(:api2) { Her::API.new :url => "https://api2.example.com" }

    before do
      spawn_model("Foo::User")
      spawn_model("Foo::Comment")
      Her::API.setup :url => "https://api.example.com"
    end

    context "when binding a model to an instance of Her::API" do
      before { Foo::User.uses_api api1 }
      subject { Foo::User.her_api }
      its(:base_uri) { should == "https://api1.example.com" }
    end

    context "when binding a model directly to Her::API" do
      before { spawn_model "Foo::User" }
      subject { Foo::User.her_api }
      its(:base_uri) { should == "https://api.example.com" }
    end

    context "when using a proc for uses_api" do
      before do
        Foo::User.uses_api lambda { Her::API.new :url => 'http://api-lambda.example.com' }
      end

      specify { Foo::User.her_api.base_uri.should == 'http://api-lambda.example.com' }
    end

    context "when binding two models to two different instances of Her::API" do
      before do
        Foo::User.uses_api api1
        Foo::Comment.uses_api api2
      end

      specify { Foo::User.her_api.base_uri.should == "https://api1.example.com" }
      specify { Foo::Comment.her_api.base_uri.should == "https://api2.example.com" }
    end

    context "binding one model to Her::API and another one to an instance of Her::API" do
      before { Foo::Comment.uses_api api2 }
      specify { Foo::User.her_api.base_uri.should == "https://api.example.com" }
      specify { Foo::Comment.her_api.base_uri.should == "https://api2.example.com" }
    end

    context "when binding a model to its superclass' her_api" do
      before do
        spawn_model "Foo::Superclass"
        Foo::Superclass.uses_api api1
        Foo::Subclass = Class.new(Foo::Superclass)
      end

      specify { Foo::Subclass.her_api.should == Foo::Superclass.her_api }
    end

    context "when changing her_api without changing the parent class' her_api" do
      before do
        spawn_model "Foo::Superclass"
        Foo::Subclass = Class.new(Foo::Superclass)
        Foo::Superclass.uses_api api1
        Foo::Subclass.uses_api api2
      end

      specify { Foo::Subclass.her_api.should_not == Foo::Superclass.her_api }
    end
  end

  context "making HTTP requests" do
    before do
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users") { |env| [200, {}, [{ :id => 1 }].to_json] }
          stub.get("/users/1") { |env| [200, {}, { :id => 1 }.to_json] }
          stub.get("/users/popular") do |env|
            if env[:params]["page"] == "2"
              [200, {}, [{ :id => 3 }, { :id => 4 }].to_json]
            else
              [200, {}, [{ :id => 1 }, { :id => 2 }].to_json]
            end
          end
        end
      end

      spawn_model "Foo::User"
    end

    describe :get do
      subject { Foo::User.get(:popular) }
      its(:length) { should == 2 }
      specify { subject.first.id.should == 1 }
    end

    describe :get_raw do
      context "with a block" do
        specify do
          Foo::User.get_raw("/users") do |parsed_data, response|
            parsed_data[:data].should == [{ :id => 1 }]
          end
        end
      end

      context "with a return value" do
        subject { Foo::User.get_raw("/users") }
        specify { subject[:parsed_data][:data].should == [{ :id => 1 }] }
      end
    end

    describe :get_collection do
      context "with a String path" do
        subject { Foo::User.get_collection("/users/popular") }
        its(:length) { should == 2 }
        specify { subject.first.id.should == 1 }
      end

      context "with a Symbol" do
        subject { Foo::User.get_collection(:popular) }
        its(:length) { should == 2 }
        specify { subject.first.id.should == 1 }
      end

      context "with extra parameters" do
        subject { Foo::User.get_collection(:popular, :page => 2) }
        its(:length) { should == 2 }
        specify { subject.first.id.should == 3 }
      end
    end

    describe :get_resource do
      context "with a String path" do
        subject { Foo::User.get_resource("/users/1") }
        its(:id) { should == 1 }
      end

      context "with a Symbol" do
        subject { Foo::User.get_resource(:"1") }
        its(:id) { should == 1 }
      end
    end

    describe :get_raw do
      specify do
        Foo::User.get_raw(:popular) do |parsed_data, response|
          parsed_data[:data].should == [{ :id => 1 }, { :id => 2 }]
        end
      end
    end
  end

  context "setting custom HTTP requests" do
    before do
      Her::API.setup :url => "https://api.example.com" do |connection|
        connection.use Her::Middleware::FirstLevelParseJSON
        connection.adapter :test do |stub|
          stub.get("/users/popular") { |env| [200, {}, [{ :id => 1 }, { :id => 2 }].to_json] }
          stub.post("/users/from_default") { |env| [200, {}, { :id => 4 }.to_json] }
        end
      end

      spawn_model "Foo::User"
    end

    subject { Foo::User }

    describe :custom_get do
      context "without cache" do
        before { Foo::User.custom_get :popular, :recent }
        it { should respond_to(:popular) }
        it { should respond_to(:recent) }

        context "making the HTTP request" do
          subject { Foo::User.popular }
          its(:length) { should == 2 }
        end
      end
    end

    describe :custom_post do
      before { Foo::User.custom_post :from_default }
      it { should respond_to(:from_default) }

      context "making the HTTP request" do
        subject { Foo::User.from_default(:name => "Tobias Fünke") }
        its(:id) { should == 4 }
      end
    end
  end
end
