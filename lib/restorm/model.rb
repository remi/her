require "restorm/model/base"
require "restorm/model/deprecated_methods"
require "restorm/model/http"
require "restorm/model/attributes"
require "restorm/model/relation"
require "restorm/model/orm"
require "restorm/model/parse"
require "restorm/model/associations"
require "restorm/model/introspection"
require "restorm/model/paths"
require "restorm/model/nested_attributes"
require "active_model"

module Restorm
  # This module is the main element of Restorm. After creating a Restorm::API object,
  # include this module in your models to get a few magic methods defined in them.
  #
  # @example
  #   class User
  #     include Restorm::Model
  #   end
  #
  #   @user = User.new(:name => "Rémi")
  #   @user.save
  module Model
    extend ActiveSupport::Concern

    # Restorm modules
    include Restorm::Model::Base
    include Restorm::Model::DeprecatedMethods
    include Restorm::Model::Attributes
    include Restorm::Model::ORM
    include Restorm::Model::HTTP
    include Restorm::Model::Parse
    include Restorm::Model::Introspection
    include Restorm::Model::Paths
    include Restorm::Model::Associations
    include Restorm::Model::NestedAttributes

    # Supported ActiveModel modules
    include ActiveModel::AttributeMethods
    include ActiveModel::Validations
    include ActiveModel::Validations::Callbacks
    include ActiveModel::Conversion
    include ActiveModel::Dirty

    # Class methods
    included do
      # Assign the default API
      use_api Restorm::API.default_api
      method_for :create, :post
      method_for :update, :put
      method_for :find, :get
      method_for :destroy, :delete
      method_for :new, :get

      # Define the default primary key
      primary_key :id

      # Define default storage accessors for errors and metadata
      store_response_errors :response_errors
      store_metadata :metadata

      # Include ActiveModel naming methods
      extend ActiveModel::Translation

      # Configure ActiveModel callbacks
      extend ActiveModel::Callbacks
      define_model_callbacks :create, :update, :save, :find, :destroy, :initialize

      # Define matchers for attr? and attr= methods
      define_attribute_method_matchers
    end
  end
end
