module Her
  module Model
    # This module adds relationships to models
    module Relationships
      # Return relationships
      def relationships # {{{
        @her_relationships
      end # }}}

      # Define an *has_many* relationship for the resource
      #
      # * `User.has_many :comments` is used to check if the "user" JSON
      #   resource we receive has a `comments` key and map it to an array
      #   of Comment.new objects
      # * `User.has_many :comments` creates a User.comments method to would
      #   make an extra HTTP request if there was no "comments" key
      def has_many(name, attrs={}) # {{{
        @her_relationships ||= {}
        (@her_relationships[:has_many] ||= []) << attrs.merge(:name => name)
      end # }}}

      # Define a *belongs_to* relationship for the resource
      #
      # * `User.belongs_to :organzation` is used to check if the "user" JSON
      #   resource we receive has an `organzation` key and map it to
      #   an Organization.new object
      #
      # * `User.belongs_to :organzation` creates a User.organzation method
      def belongs_to(name, attrs={}) # {{{
        @her_relationships ||= {}
        (@her_relationships[:belongs_to] ||= []) << attrs.merge(:name => name)
      end # }}}
    end
  end
end
