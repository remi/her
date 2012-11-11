# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe Her::Model::Hooks do
  context "adding hooks to a model" do
    before do
      spawn_model "Foo::User"
    end

    describe "method hooks" do
      it "handles “before save” method hooks" do
        Foo::User.before_save :set_internal_id
        Foo::User.hooks[:before_save].length.should == 1
        Foo::User.hooks[:before_save].first.class.should == Symbol
      end

      it "handles “before create” method hooks" do
        Foo::User.before_create :set_internal_id
        Foo::User.hooks[:before_create].length.should == 1
        Foo::User.hooks[:before_create].first.class.should == Symbol
      end

      it "handles “before update” method hooks" do
        Foo::User.before_update :set_internal_id
        Foo::User.hooks[:before_update].length.should == 1
        Foo::User.hooks[:before_update].first.class.should == Symbol
      end

      it "handles “before destroy” method hooks" do
        Foo::User.before_destroy :set_internal_id
        Foo::User.hooks[:before_destroy].length.should == 1
        Foo::User.hooks[:before_destroy].first.class.should == Symbol
      end

      it "handles “after save” method hooks" do
        Foo::User.after_save :set_internal_id
        Foo::User.hooks[:after_save].length.should == 1
        Foo::User.hooks[:after_save].first.class.should == Symbol
      end

      it "handles “after create” method hooks" do
        Foo::User.after_create :set_internal_id
        Foo::User.hooks[:after_create].length.should == 1
        Foo::User.hooks[:after_create].first.class.should == Symbol
      end

      it "handles “after update” method hooks" do
        Foo::User.after_update :set_internal_id
        Foo::User.hooks[:after_update].length.should == 1
        Foo::User.hooks[:after_update].first.class.should == Symbol
      end

      it "handles “after destroy” method hooks" do
        Foo::User.after_destroy :set_internal_id
        Foo::User.hooks[:after_destroy].length.should == 1
        Foo::User.hooks[:after_destroy].first.class.should == Symbol
      end
    end

    describe "block hooks" do
      it "handles “before save” block hooks" do
        Foo::User.before_save { |record| record.internal_id = 42 }
        Foo::User.hooks[:before_save].length.should == 1
        Foo::User.hooks[:before_save].first.class.should == Proc
      end

      it "handles “before create” block hooks" do
        Foo::User.before_create { |record| record.internal_id = 42 }
        Foo::User.hooks[:before_create].length.should == 1
        Foo::User.hooks[:before_create].first.class.should == Proc
      end

      it "handles “before update” block hooks" do
        Foo::User.before_update { |record| record.internal_id = 42 }
        Foo::User.hooks[:before_update].length.should == 1
        Foo::User.hooks[:before_update].first.class.should == Proc
      end

      it "handles “before destroy” block hooks" do
        Foo::User.before_destroy { |record| record.internal_id = 42 }
        Foo::User.hooks[:before_destroy].length.should == 1
        Foo::User.hooks[:before_destroy].first.class.should == Proc
      end

      it "handles “after save” block hooks" do
        Foo::User.after_save { |record| record.internal_id = 42 }
        Foo::User.hooks[:after_save].length.should == 1
        Foo::User.hooks[:after_save].first.class.should == Proc
      end

      it "handles “after create” block hooks" do
        Foo::User.after_create { |record| record.internal_id = 42 }
        Foo::User.hooks[:after_create].length.should == 1
        Foo::User.hooks[:after_create].first.class.should == Proc
      end

      it "handles “after update” block hooks" do
        Foo::User.after_update { |record| record.internal_id = 42 }
        Foo::User.hooks[:after_update].length.should == 1
        Foo::User.hooks[:after_update].first.class.should == Proc
      end

      it "handles “after destroy” block hooks" do
        Foo::User.after_destroy { |record| record.internal_id = 42 }
        Foo::User.hooks[:after_destroy].length.should == 1
        Foo::User.hooks[:after_destroy].first.class.should == Proc
      end
    end

    context "inheriting hooks from a superclass" do
      it "copies hooks to the subclass" do
        Foo::User.before_save :set_internal_id
        Foo::User.after_create { |record| record.internal_id = 42 }
        subclass = Class.new(Foo::User)
        subclass.hooks.object_id.should_not == Foo::User.hooks.object_id
        subclass.hooks[:before_save].should == [:set_internal_id]
        subclass.hooks[:after_create].length.should == 1
      end
    end
  end

  context "perform hooks on a model" do
    before do
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.post("/users")     { |env| [200, {}, { :id => 1, :name => "Tobias Fünke" }.to_json] }
          stub.get("/users/1")    { |env| [200, {}, { :id => 1, :name => "Tobias Fünke" }.to_json] }
          stub.put("/users/1")    { |env| [200, {}, { :id => 1, :name => "Tobias Fünke" }.to_json] }
          stub.delete("/users/1") { |env| [200, {}, { :id => 1, :name => "Tobias Fünke" }.to_json] }
        end
      end

      spawn_model "Foo::User" do
        attr_accessor :internal_save_id, :internal_create_id, :internal_update_id, :internal_destroy_id
        attr_accessor :internal_after_save_id, :internal_after_create_id, :internal_after_update_id, :internal_after_destroy_id

        def change_internal_save_id; @internal_save_id = 100; end
        def change_internal_create_id; @internal_create_id = 101; end
        def change_internal_update_id; @internal_update_id = 102; end
        def change_internal_destroy_id; @internal_destroy_id = 103; end

        def change_internal_after_save_id; @internal_after_save_id = 100; end
        def change_internal_after_create_id; @internal_after_create_id = 101; end
        def change_internal_after_update_id; @internal_after_update_id = 102; end
        def change_internal_after_destroy_id; @internal_after_destroy_id = 103; end
      end
    end

    describe "method hooks" do
      before do
        Foo::User.before_save :change_internal_save_id
        Foo::User.before_update :change_internal_update_id
        Foo::User.before_create :change_internal_create_id
        Foo::User.before_destroy :change_internal_destroy_id

        Foo::User.after_save :change_internal_after_save_id
        Foo::User.after_update :change_internal_after_update_id
        Foo::User.after_create :change_internal_after_create_id
        Foo::User.after_destroy :change_internal_after_destroy_id
      end

      it "perform “before save” “before create” method hook on Model#save without an ID" do
        @user = Foo::User.new(:fullname => "Tobias Fünke")
        @user.save
        @user.internal_save_id.should == 100
        @user.internal_create_id.should == 101
        @user.internal_update_id.should == nil
      end

      it "perform “before save” and “before update” method hook on Model#save with an ID" do
        @user = Foo::User.find(1)
        @user.save
        @user.internal_save_id.should == 100
        @user.internal_create_id.should == nil
        @user.internal_update_id.should == 102
      end

      it "perform “before destroy” method hook on Model#destroy" do
        @user = Foo::User.find(1)
        @user.destroy
        @user.internal_save_id.should == nil
        @user.internal_create_id.should == nil
        @user.internal_update_id.should == nil
        @user.internal_destroy_id.should == 103
      end

      it "perform “after save” “after create” method hook on Model#save without an ID" do
        @user = Foo::User.new(:fullname => "Tobias Fünke")
        @user.save
        @user.internal_after_save_id.should == 100
        @user.internal_after_create_id.should == 101
        @user.internal_after_update_id.should == nil
      end

      it "perform “after save” “after update” method hook on Model#save with an ID" do
        @user = Foo::User.find(1)
        @user.save
        @user.internal_after_save_id.should == 100
        @user.internal_after_create_id.should == nil
        @user.internal_after_update_id.should == 102
      end

      it "perform “after save” “after update” method hook on Model.save_existing" do
        @user = Foo::User.save_existing(1, { :fullname => "Tobias Fünke" })
        @user.internal_after_save_id.should == 100
        @user.internal_after_create_id.should == nil
        @user.internal_after_update_id.should == 102
      end

      it "perform “after save” “after create” method hook on Model.create" do
        @user = Foo::User.create({ :fullname => "Tobias Fünke" })
        @user.internal_after_save_id.should == 100
        @user.internal_after_create_id.should == 101
        @user.internal_after_update_id.should == nil
      end
    end

    describe "block hooks" do
      before do
        Foo::User.before_save { |record| record.internal_save_id = 200 }
        Foo::User.before_create { |record| record.internal_create_id = 201 }
        Foo::User.before_update { |record| record.internal_update_id = 202 }
        Foo::User.before_destroy { |record| record.internal_destroy_id = 203 }

        Foo::User.after_save { |record| record.internal_after_save_id = 200 }
        Foo::User.after_create { |record| record.internal_after_create_id = 201 }
        Foo::User.after_update { |record| record.internal_after_update_id = 202 }
        Foo::User.after_destroy { |record| record.internal_after_destroy_id = 203 }
      end

      it "perform “before save” and “before create” block hook on Model#save without an ID" do
        @user = Foo::User.new(:fullname => "Tobias Fünke")
        @user.save
        @user.internal_save_id.should == 200
        @user.internal_create_id.should == 201
        @user.internal_update_id.should == nil
      end

      it "perform “before save” and “before update” block hook on Model#save with an ID" do
        @user = Foo::User.find(1)
        @user.save
        @user.internal_save_id.should == 200
        @user.internal_create_id.should == nil
        @user.internal_update_id.should == 202
      end

      it "perform “before destroy” block hook on Model#destroy" do
        @user = Foo::User.find(1)
        @user.destroy
        @user.internal_save_id.should == nil
        @user.internal_create_id.should == nil
        @user.internal_update_id.should == nil
        @user.internal_destroy_id.should == 203
      end

      it "perform “after save” “after create” block hook on Model#save without an ID" do
        @user = Foo::User.new(:fullname => "Tobias Fünke")
        @user.save
        @user.internal_after_save_id.should == 200
        @user.internal_after_create_id.should == 201
        @user.internal_after_update_id.should == nil
      end

      it "perform “after save” “after update” block hook on Model#save with an ID" do
        @user = Foo::User.find(1)
        @user.save
        @user.internal_after_save_id.should == 200
        @user.internal_after_create_id.should == nil
        @user.internal_after_update_id.should == 202
      end
    end
  end
end
