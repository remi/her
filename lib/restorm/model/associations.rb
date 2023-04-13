require "restorm/model/associations/association"
require "restorm/model/associations/association_proxy"
require "restorm/model/associations/belongs_to_association"
require "restorm/model/associations/has_many_association"
require "restorm/model/associations/has_one_association"

module Restorm
  module Model
    # This module adds associations to models
    module Associations
      extend ActiveSupport::Concern

      # Returns true if the model has a association_name association, false otherwise.
      #
      # @private
      def has_association?(association_name)
        associations = self.class.associations.values.flatten.map { |r| r[:name] }
        associations.include?(association_name)
      end

      # Returns the resource/collection corresponding to the association_name association.
      #
      # @private
      def get_association(association_name)
        send(association_name) if has_association?(association_name)
      end

      module ClassMethods
        # Return @_restorm_associations, lazily initialized with copy of the
        # superclass' her_associations, or an empty hash.
        #
        # @private
        def associations
          @_restorm_associations ||= begin
            superclass.respond_to?(:associations) ? superclass.associations.dup : Hash.new { |h, k| h[k] = [] }
          end
        end

        # @private
        def association_names
          associations.inject([]) { |memo, (_, details)| memo << details }.flatten.map { |a| a[:name] }
        end

        # @private
        def association_keys
          associations.inject([]) { |memo, (_, details)| memo << details }.flatten.map { |a| a[:data_key] }
        end

        # Parse associations data after initializing a new object
        #
        # @private
        def parse_associations(data)
          associations.each_pair do |type, definitions|
            definitions.each do |association|
              association_class = "restorm/model/associations/#{type}_association".classify.constantize
              data.merge! association_class.parse(association, self, data)
            end
          end

          data
        end

        # Define an *has_many* association.
        #
        # @param [Symbol] name The name of the method added to resources
        # @param [Hash] opts Options
        # @option opts [String] :class_name The name of the class to map objects to
        # @option opts [Symbol] :data_key The attribute where the data is stored
        # @option opts [Path] :path The relative path where to fetch the data (defaults to `/{name}`)
        #
        # @example
        #   class User
        #     include Restorm::Model
        #     has_many :articles
        #   end
        #
        #   class Article
        #     include Restorm::Model
        #   end
        #
        #   @user = User.find(1)
        #   @user.articles # => [#<Article(articles/2) id=2 title="Hello world.">]
        #   # Fetched via GET "/users/1/articles"
        def has_many(name, opts = {})
          Restorm::Model::Associations::HasManyAssociation.attach(self, name, opts)
        end

        # Define an *has_one* association.
        #
        # @param [Symbol] name The name of the method added to resources
        # @param [Hash] opts Options
        # @option opts [String] :class_name The name of the class to map objects to
        # @option opts [Symbol] :data_key The attribute where the data is stored
        # @option opts [Path] :path The relative path where to fetch the data (defaults to `/{name}`)
        #
        # @example
        #   class User
        #     include Restorm::Model
        #     has_one :organization
        #   end
        #
        #   class Organization
        #     include Restorm::Model
        #   end
        #
        #   @user = User.find(1)
        #   @user.organization # => #<Organization(organizations/2) id=2 name="Foobar Inc.">
        #   # Fetched via GET "/users/1/organization"
        def has_one(name, opts = {})
          Restorm::Model::Associations::HasOneAssociation.attach(self, name, opts)
        end

        # Define a *belongs_to* association.
        #
        # @param [Symbol] name The name of the method added to resources
        # @param [Hash] opts Options
        # @option opts [String] :class_name The name of the class to map objects to
        # @option opts [Symbol] :data_key The attribute where the data is stored
        # @option opts [Path] :path The relative path where to fetch the data
        # @option opts [Symbol] :foreign_key The foreign key used to build the `:id` part of the path (defaults to `{name}_id`)
        #
        # @example
        #   class User
        #     include Restorm::Model
        #     belongs_to :team, :class_name => "Group"
        #   end
        #
        #   class Group
        #     include Restorm::Model
        #   end
        #
        #   @user = User.find(1) # => #<User(users/1) id=1 team_id=2 name="Tobias">
        #   @user.team # => #<Team(teams/2) id=2 name="Developers">
        #   # Fetched via GET "/teams/2"
        def belongs_to(name, opts = {})
          Restorm::Model::Associations::BelongsToAssociation.attach(self, name, opts)
        end
      end
    end
  end
end
