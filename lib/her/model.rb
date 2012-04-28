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
    autoload :Base,          "her/model/base"
    autoload :HTTP,          "her/model/http"
    autoload :ORM,           "her/model/orm"
    autoload :Relationships, "her/model/relationships"
    autoload :Hooks,         "her/model/hooks"
    autoload :Introspection, "her/model/introspection"
    autoload :Paths,         "her/model/paths"

    extend ActiveSupport::Concern

    # Instance methods
    include Her::Model::ORM
    include Her::Model::Introspection
    include Her::Model::Paths

    # Class methods
    included do
      extend Her::Model::Base
      extend Her::Model::HTTP
      extend Her::Model::ORM
      extend Her::Model::Relationships
      extend Her::Model::Hooks
      extend Her::Model::Paths

      # Define default settings
      collection_path "/#{self.to_s.downcase.pluralize}"
      resource_path "/#{self.to_s.downcase.pluralize}/:id"
      uses_api Her::API.default_api
    end
  end
end
