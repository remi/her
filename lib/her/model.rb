require "her/model/base"
require "her/model/http"
require "her/model/orm"
require "her/model/relationships"
require "her/model/hooks"
require "her/model/introspection"
require "her/model/paths"

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

    # Class methods
    included do
      extend Her::Model::Base
      extend Her::Model::HTTP
      extend Her::Model::Relationships
      extend Her::Model::Hooks

      # Define default settings
      base_path = self.name.split("::").last.underscore.pluralize
      collection_path "#{base_path}"
      resource_path "#{base_path}/:id"
      uses_api Her::API.default_api
    end
  end
end
