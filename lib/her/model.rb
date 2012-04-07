module Her
  # This module is the main element of Her. After creating a Her::API object, include
  # this module in your models to get a few magic methods defined in them.
  #
  # @example
  #   class User
  #     include Her::Model
  #     uses_api $api
  #   end
  #
  #   @user = User.new(:name => "Rémi")
  #   @user.save
  #
  module Model
    # @private
    def self.included(base) # {{{
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end # }}}

    module InstanceMethods
    end

    module ClassMethods
      # Main wrapper around Her::API
      # @private
      def request(attrs={}) # {{{
        p "relationships are"
        p @her_relationships
        response = @her_api.request(attrs)
        @her_api.parse(response)
      end # }}}

      # Make a GET request and return the parsed JSON response
      def get(path, attrs={}) # {{{
        request attrs.merge(:path => path)
      end # }}}

      # Link a model with a Her::API object
      def uses_api(api) # {{{
        @her_api = api
      end # }}}

      # Define an *has_many* relationship for the resource
      #
      # `User.has_many :comments` is used to check if the "user" JSON
      #  resource we receive has a `comments` key and map it to an array
      #  of Comment.new objects
      #
      # `User.has_many :comments` creates a User.comments method to would
      #  make an extra HTTP request if there was no "comments" key
      def has_many(name, attrs={}) # {{{
        @her_relationships ||= {}
        (@her_relationships[:has_many] ||= []) << attrs.merge(:name => name)
      end # }}}

      # Define a *belongs_to* relationship for the resource
      #
      # `User.belongs_to :organzation` is used to check if the "user" JSON
      # resource we receive has an `organzation` key and map it to
      # an Organization.new object
      #
      # `User.belongs_to :organzation` creates a User.organzation method
      def belongs_to(name, attrs={}) # {{{
        @her_relationships ||= {}
        (@her_relationships[:belongs_to] ||= []) << attrs.merge(:name => name)
      end # }}}
    end
  end
end
