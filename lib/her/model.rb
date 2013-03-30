require "her/model/base"
require "her/model/http"
require "her/model/orm"
require "her/model/associations"
require "her/model/introspection"
require "her/model/paths"
require "her/model/nested_attributes"
require "active_model"

module Her
  # This module is the main element of Her. After creating a Her::API object,
  # include this module in your models to get a few magic methods defined in them.
  #
  # @example
  #   class User
  #     include Her::Model
  #   end
  #
  #   @user = User.new(:name => "Rémi")
  #   @user.save
  module Model
    extend ActiveSupport::Concern

    # Instance methods
    include Her::Model::ORM
    include Her::Model::Introspection
    include Her::Model::Paths
    include Her::Model::Associations
    include Her::Model::NestedAttributes
    include ActiveModel::Validations
    include ActiveModel::Conversion
    include ActiveModel::Dirty

    # Class methods
    included do
      extend Her::Model::Base
      extend Her::Model::HTTP
      extend ActiveModel::Naming
      extend ActiveModel::Translation

      extend ActiveModel::Callbacks
      define_model_callbacks :create, :update, :save, :find, :destroy

      # Define default settings
      root_element self.name.split("::").last.underscore
      base_path = root_element.pluralize
      collection_path "#{base_path}"
      resource_path "#{base_path}/:id"
      uses_api Her::API.default_api
    end

    # Returns true if attribute_name is
    # * in orm data
    # * an association
    def has_key?(attribute_name)
      has_data?(attribute_name) ||
      has_association?(attribute_name)
    end

    # Returns
    # * the value of the attribute_nane attribute if it's in orm data
    # * the resource/collection corrsponding to attribute_name if it's an association
    def [](attribute_name)
      get_data(attribute_name) ||
      get_association(attribute_name)
    end
  end
end
