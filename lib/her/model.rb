module Her
  # This module is the main element of Her. After creating a Her::API object,
  # include this module in your models to get a few magic methods defined in them.
  #
  # @example
  #   class User
  #     include Her::Model
  #     uses_api $api
  #   end
  #
  #   @user = User.new(:name => "Rémi")
  module Model
    autoload :Base,          "her/model/base"
    autoload :HTTP,          "her/model/http"
    autoload :ORM,           "her/model/orm"
    autoload :Relationships, "her/model/relationships"

    extend ActiveSupport::Concern

    # Instance methods
    include Her::Model::ORM

    # Class methods
    included do
      @her_collection_path = "/#{self.to_s.downcase.pluralize}"
      extend Her::Model::Base
      extend Her::Model::HTTP
      extend Her::Model::ORM
      extend Her::Model::Relationships
    end
  end
end
