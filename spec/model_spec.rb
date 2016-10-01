# encoding: utf-8
require "spec_helper"

describe Her::Model do
  before do
    Her::API.setup url: "https://api.example.com" do |connection|
      connection.use Her::Middleware::FirstLevelParseJSON
      connection.adapter :test do |stub|
        stub.get("/users/1") { [200, {}, { id: 1, name: "Tobias Fünke" }.to_json] }
        stub.get("/users/1/comments") { [200, {}, [{ id: 4, body: "They're having a FIRESALE?" }].to_json] }
      end
    end

    spawn_model("Foo::User") { has_many :comments }
    spawn_model("Foo::Comment")
  end
  subject { Foo::User.find(1) }

  describe :has_key? do
    it { is_expected.not_to have_key(:unknown_method_for_a_user) }
    it { is_expected.not_to have_key(:unknown_method_for_a_user) }
    it { is_expected.to have_key(:name) }
    it { is_expected.to have_key(:comments) }
  end

  describe :serialization do
    it "should be serialized without an error" do
      expect { Marshal.dump(subject.comments) }.not_to raise_error
    end

    it "should correctly load serialized object" do
      serialized_comments = Marshal.load(Marshal.dump(subject.comments))
      expect(subject.comments.size).to eq(serialized_comments.size)
      expect(subject.comments.first.id).to eq(serialized_comments.first.id)
      expect(subject.comments.first.body).to eq(serialized_comments.first.body)
    end
  end

  describe :[] do
    it { is_expected.not_to have_key(:unknown_method_for_a_user) }
    specify { expect(subject[:name]).to eq("Tobias Fünke") }
    specify { expect(subject[:comments].first.body).to eq("They're having a FIRESALE?") }
  end
end
