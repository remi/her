require "her/model/associations/association"
require "her/model/associations/belongs_to_association"
require "her/model/associations/has_many_association"
require "her/model/associations/has_one_association"

module Her
  module Model
    # This module adds associations to models
    module Associations
      extend ActiveSupport::Concern

      # Returns true if the model has a association_name association, false otherwise.
      def has_association?(association_name)
        associations = self.class.associations.values.flatten.map { |r| r[:name] }
        associations.include?(association_name)
      end
      alias :has_relationship? :has_association?

      # Returns the resource/collection corresponding to the association_name association.
      def get_association(association_name)
        send(association_name) if has_association?(association_name)
      end
      alias :get_relationship :get_association

      module ClassMethods
        # Return @_her_associations, lazily initialized with copy of the
        # superclass' her_associations, or an empty hash.
        #
        # @private
        def associations
          @_her_associations ||= begin
            superclass.respond_to?(:associations) ? superclass.associations.dup : Hash.new { |h,k| h[k] = [] }
          end
        end
        alias :relationships :associations

        # Parse associations data after initializing a new object
        #
        # @private
        def parse_associations(data)
          associations.each_pair do |type, definitions|
            definitions.each do |association|
              data_key = association[:data_key]
              next unless data[data_key]

              klass = self.her_nearby_class(association[:class_name])
              name = association[:name]

              data[name] = case type
                when :has_many
                  Her::Model::Attributes.initialize_collection(klass, :data => data[data_key])
                when :has_one, :belongs_to
                  klass.class_for_data(klass.parse(data[data_key])).new(data[data_key])
                else
                  nil
              end
            end
          end
          data
        end

        # Define an *has_many* association.
        #
        # @param [Symbol] name The name of the model
        # @param [Hash] attrs Options (currently not used)
        #
        # @example
        #   class User
        #     include Her::Model
        #     has_many :articles
        #   end
        #
        #   class Article
        #     include Her::Model
        #   end
        #
        #   @user = User.find(1)
        #   @user.articles # => [#<Article(articles/2) id=2 title="Hello world.">]
        #   # Fetched via GET "/users/1/articles"
        def has_many(name, attrs={})
          Her::Model::Associations::HasManyAssociation.attach(self, name, attrs)
        end

        # Define an *has_one* association.
        #
        # @param [Symbol] name The name of the model
        # @param [Hash] attrs Options
        #
        # @example
        #   class User
        #     include Her::Model
        #     has_one :organization
        #   end
        #
        #   class Organization
        #     include Her::Model
        #   end
        #
        #   @user = User.find(1)
        #   @user.organization # => #<Organization(organizations/2) id=2 name="Foobar Inc.">
        #   # Fetched via GET "/users/1/organization"
        def has_one(name, attrs={})
          Her::Model::Associations::HasOneAssociation.attach(self, name, attrs)
        end

        # Define a *belongs_to* association.
        #
        # @param [Symbol] name The name of the model
        # @param [Hash] attrs Options
        #
        # @example
        #   class User
        #     include Her::Model
        #     belongs_to :team, :class_name => "Group"
        #   end
        #
        #   class Group
        #     include Her::Model
        #   end
        #
        #   @user = User.find(1) # => #<User(users/1) id=1 team_id=2 name="Tobias">
        #   @user.team # => #<Team(teams/2) id=2 name="Developers">
        #   # Fetched via GET "/teams/2"
        def belongs_to(name, attrs={})
          Her::Model::Associations::BelongsToAssociation.attach(self, name, attrs)
        end
      end
    end
  end
end
