# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe Her::Model::Hooks do
  context "adding hooks to a model" do
    before do # {{{
      Object.instance_eval { remove_const :User } if Object.const_defined?(:User)
      class User
        include Her::Model
      end
    end # }}}

    describe "method hooks" do
    it "handles “before save” method hooks" do # {{{
      User.before_save :set_internal_id
      User.hooks[:before_save].length.should == 1
      User.hooks[:before_save].first.class.should == Symbol
    end # }}}

    it "handles “before create” method hooks" do # {{{
      User.before_create :set_internal_id
      User.hooks[:before_create].length.should == 1
      User.hooks[:before_create].first.class.should == Symbol
    end # }}}

    it "handles “before update” method hooks" do # {{{
      User.before_update :set_internal_id
      User.hooks[:before_update].length.should == 1
      User.hooks[:before_update].first.class.should == Symbol
    end # }}}

    it "handles “before destroy” method hooks" do # {{{
      User.before_destroy :set_internal_id
      User.hooks[:before_destroy].length.should == 1
      User.hooks[:before_destroy].first.class.should == Symbol
    end # }}}
    end

    describe "block hooks" do
    it "handles “before save” block hooks" do # {{{
      User.before_save { |record| record.internal_id = 42 }
      User.hooks[:before_save].length.should == 1
      User.hooks[:before_save].first.class.should == Proc
    end # }}}

    it "handles “before create” block hooks" do # {{{
      User.before_create { |record| record.internal_id = 42 }
      User.hooks[:before_create].length.should == 1
      User.hooks[:before_create].first.class.should == Proc
    end # }}}

    it "handles “before update” block hooks" do # {{{
      User.before_update { |record| record.internal_id = 42 }
      User.hooks[:before_update].length.should == 1
      User.hooks[:before_update].first.class.should == Proc
    end # }}}

    it "handles “before destroy” block hooks" do # {{{
      User.before_destroy { |record| record.internal_id = 42 }
      User.hooks[:before_destroy].length.should == 1
      User.hooks[:before_destroy].first.class.should == Proc
    end # }}}
    end
  end

  context "perform hooks on a model" do
      before do # {{{
        Her::API.setup :base_uri => "https://api.example.com"
        FakeWeb.register_uri(:post, "https://api.example.com/users", :body => { :data => { :id => 1, :name => "Tobias Fünke" } }.to_json)
        FakeWeb.register_uri(:get, "https://api.example.com/users/1", :body => { :data => { :id => 1, :name => "Tobias Fünke" } }.to_json)
        FakeWeb.register_uri(:put, "https://api.example.com/users/1", :body => { :data => { :id => 1, :name => "Tobias Fünke" } }.to_json)
        FakeWeb.register_uri(:delete, "https://api.example.com/users/1", :body => { :data => { :id => 1, :name => "Tobias Fünke" } }.to_json)

        Object.instance_eval { remove_const :User } if Object.const_defined?(:User)
        class User
          include Her::Model
          attr_accessor :internal_save_id, :internal_create_id, :internal_update_id, :internal_destroy_id

          def change_internal_save_id
            @internal_save_id = 100
          end

          def change_internal_create_id
            @internal_create_id = 101
          end

          def change_internal_update_id
            @internal_update_id = 102
          end

          def change_internal_destroy_id
            @internal_destroy_id = 103
          end
        end
      end # }}}

    describe "method hooks" do
      before do # {{{
        User.before_save :change_internal_save_id
        User.before_update :change_internal_update_id
        User.before_create :change_internal_create_id
        User.before_destroy :change_internal_destroy_id
      end # }}}

      it "perform “before save” “before create” method hook before creating a resource" do # {{{
        @user = User.new(:fullname => "Tobias Fünke")
        @user.save
        @user.internal_save_id.should == 100
        @user.internal_create_id.should == 101
        @user.internal_update_id.should == nil
      end # }}}

      it "perform “before save” and “before update” method hook before updating a resource" do # {{{
        @user = User.find(1)
        @user.save
        @user.internal_save_id.should == 100
        @user.internal_create_id.should == nil
        @user.internal_update_id.should == 102
      end # }}}

      it "perform “before destroy” method hook before destroying a resource" do # {{{
        @user = User.find(1)
        @user.destroy
        @user.internal_save_id.should == nil
        @user.internal_create_id.should == nil
        @user.internal_update_id.should == nil
        @user.internal_destroy_id.should == 103
      end # }}}
    end

    describe "block hooks" do
      before do # {{{
        User.before_save { |record| record.internal_save_id = 200 }
        User.before_create { |record| record.internal_create_id = 201 }
        User.before_update { |record| record.internal_update_id = 202 }
        User.before_destroy { |record| record.internal_destroy_id = 203 }
      end # }}}

      it "perform “before save” and “before create” block hook before creating a resource" do # {{{
        @user = User.new(:fullname => "Tobias Fünke")
        @user.save
        @user.internal_save_id.should == 200
        @user.internal_create_id.should == 201
        @user.internal_update_id.should == nil
      end # }}}

      it "perform “before save” and “before update” block hook before updating a resource" do # {{{
        @user = User.find(1)
        @user.save
        @user.internal_save_id.should == 200
        @user.internal_create_id.should == nil
        @user.internal_update_id.should == 202
      end # }}}

      it "perform “before destroy” block hook before destroying a resource" do # {{{
        @user = User.find(1)
        @user.destroy
        @user.internal_save_id.should == nil
        @user.internal_create_id.should == nil
        @user.internal_update_id.should == nil
        @user.internal_destroy_id.should == 203
      end # }}}
    end
  end
end
