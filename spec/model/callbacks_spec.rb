# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe "Her::Model and ActiveModel::Callbacks" do
  before do
    Her::API.setup url: "https://api.example.com" do |builder|
      builder.use Her::Middleware::FirstLevelParseJSON
    end

    spawn_model "Foo::User"
  end

  context :before_save do
    subject { Foo::User.create(name: "Tobias Funke") }
    before do
      Her::API.default_api.connection.adapter :test do |stub|
        stub.post("/users") { |env| [200, {}, { id: 1, name: env[:body][:name] }.to_json] }
        stub.put("/users/1") { |env| [200, {}, { id: 1, name: env[:body][:name] }.to_json] }
      end
    end

    context "when using a symbol callback" do
      before do
        class Foo::User
          before_save :alter_name
          def alter_name
            name.upcase!
          end
        end
      end

      describe "#name" do
        subject { super().name }
        it { is_expected.to eq("TOBIAS FUNKE") }
      end
    end

    context "when using a block callback" do
      before do
        class Foo::User
          before_save -> { name.upcase! }
        end
      end

      describe "#name" do
        subject { super().name }
        it { is_expected.to eq("TOBIAS FUNKE") }
      end
    end

    context "when changing a value of an existing resource in a callback" do
      before do
        class Foo::User
          before_save :alter_name
          def alter_name
            self.name = "Lumberjack" if persisted?
          end
        end
      end

      it "should call the server with the canged value" do
        expect(subject.name).to eq("Tobias Funke")
        subject.save
        expect(subject.name).to eq("Lumberjack")
      end
    end
  end

  context :before_create do
    subject { Foo::User.create(name: "Tobias Funke") }
    before do
      Her::API.default_api.connection.adapter :test do |stub|
        stub.post("/users") { |env| [200, {}, { id: 1, name: env[:body][:name] }.to_json] }
      end
    end

    context "when using a symbol callback" do
      before do
        class Foo::User
          before_create :alter_name
          def alter_name
            name.upcase!
          end
        end
      end

      describe "#name" do
        subject { super().name }
        it { is_expected.to eq("TOBIAS FUNKE") }
      end
    end

    context "when using a block callback" do
      before do
        class Foo::User
          before_create -> { name.upcase! }
        end
      end

      describe "#name" do
        subject { super().name }
        it { is_expected.to eq("TOBIAS FUNKE") }
      end
    end
  end

  context :after_find do
    subject { Foo::User.find(1) }
    before do
      Her::API.default_api.connection.adapter :test do |stub|
        stub.get("/users/1") { [200, {}, { id: 1, name: "Tobias Funke" }.to_json] }
      end
    end

    context "when using a symbol callback" do
      before do
        class Foo::User
          after_find :alter_name
          def alter_name
            name.upcase!
          end
        end
      end

      describe "#name" do
        subject { super().name }
        it { is_expected.to eq("TOBIAS FUNKE") }
      end
    end

    context "when using a block callback" do
      before do
        class Foo::User
          after_find -> { name.upcase! }
        end
      end

      describe "#name" do
        subject { super().name }
        it { is_expected.to eq("TOBIAS FUNKE") }
      end
    end
  end

  context :after_initialize do
    subject { Foo::User.new(name: "Tobias Funke") }

    context "when using a symbol callback" do
      before do
        class Foo::User
          after_initialize :alter_name
          def alter_name
            name.upcase!
          end
        end
      end

      describe "#name" do
        subject { super().name }
        it { is_expected.to eq("TOBIAS FUNKE") }
      end
    end

    context "when using a block callback" do
      before do
        class Foo::User
          after_initialize -> { name.upcase! }
        end
      end

      describe "#name" do
        subject { super().name }
        it { is_expected.to eq("TOBIAS FUNKE") }
      end
    end
  end
end
