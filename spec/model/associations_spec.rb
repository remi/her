# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe Her::Model::Associations do
  # See spec/model/associations/*.rb for additional specs

  #--------------------------------------------------------------------------------------------
  # Her::Model::Associations#has_association?
  #--------------------------------------------------------------------------------------------
  describe :has_association? do
    subject { spawn_model('Foo::User') { has_many :comments }.new }

    it { should have_association(:comments) }
    it { should_not have_association(:unknown_association) }
  end

  #--------------------------------------------------------------------------------------------
  # Her::Model::Associations#get_association
  #--------------------------------------------------------------------------------------------
  describe :get_association do
    before do
      spawn_model('Foo::User') { has_many :comments }
      stub_api_for(Foo::User) do |stub|
        stub.get("/users/1") { ok! :id => 1, :name => "Tobias Fünke", :comments => [] }
      end
    end

    let(:user) { Foo::User.find(1) }
    specify do
      user.get_association(:unknown_association).should be_nil
      user.get_association(:comments).should be_kind_of Her::Collection
    end
  end
end
