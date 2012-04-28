module Her
  module Model
    # This module adds relationships to models
    module Relationships
      # Return relationships
      # @private
      def relationships # {{{
        @her_relationships
      end # }}}

      # Parse relationships data after initializing a new object
      # @private
      def parse_relationships(data) # {{{
        @her_relationships ||= {}
        @her_relationships.each_pair do |type, relationships|
          relationships.each do |relationship|
            if data.include?(relationship[:name])
              if type == :has_many
                data[relationship[:name]] = Her::Model::ORM.initialize_collection(relationship[:name], data[relationship[:name]])
              elsif type == :has_one
                data[relationship[:name]] = Object.const_get(relationship[:name].to_s.classify).new(data[relationship[:name]])
              elsif type == :belongs_to
                data[relationship[:name]] = Object.const_get(relationship[:name].to_s.classify).new(data[relationship[:name]])
              end
            end
          end
        end
        data
      end # }}}

      # Define an *has_many* relationship.
      #
      # @param [Symbol] name The name of the model
      # @param [Hash] attrs Options (currently not used)
      #
      # @example
      #   class User
      #     include Her::API
      #     has_many :articles
      #   end
      #
      #   class Article
      #     include Her::API
      #   end
      #
      #   @user = User.find(1)
      #   @user.articles # => [#<Article(articles/2) id=2 title="Hello world.">]
      #   # Fetched via GET "/users/1/articles"
      def has_many(name, attrs={}) # {{{
        @her_relationships ||= {}
        (@her_relationships[:has_many] ||= []) << attrs.merge(:name => name)
        collection_path = @her_collection_path

        define_method(name) do
          return @data[name] if @data.include?(name) # Do not fetch from API again if we have it in @data
          self.class.get_collection("#{collection_path}/#{id}/#{name.to_s.pluralize}")
        end
      end # }}}

      # Define an *has_one* relationship.
      #
      # @param [Symbol] name The name of the model
      # @param [Hash] attrs Options (currently not used)
      #
      # @example
      #   class User
      #     include Her::API
      #     has_one :organization
      #   end
      #
      #   class Organization
      #     include Her::API
      #   end
      #
      #   @user = User.find(1)
      #   @user.organization # => #<Organization(organizations/2) id=2 name="Foobar Inc.">
      #   # Fetched via GET "/users/1/organization"
      def has_one(name, attrs={}) # {{{
        @her_relationships ||= {}
        (@her_relationships[:has_one] ||= []) << attrs.merge(:name => name)
        collection_path = @her_collection_path

        define_method(name) do
          return @data[name] if @data.include?(name) # Do not fetch from API again if we have it in @data
          self.class.get_resource("#{collection_path}/#{id}/#{name.to_s.singularize}")
        end
      end # }}}

      # Define a *belongs_to* relationship.
      #
      # @param [Symbol] name The name of the model
      # @param [Hash] attrs Options (currently not used)
      #
      # @example
      #   class User
      #     include Her::API
      #     belongs_to :team
      #   end
      #
      #   class Team
      #     include Her::API
      #   end
      #
      #   @user = User.find(1)
      #   @user.team # => #<Team(teams/2) id=2 name="Developers">
      #   # Fetched via GET "/teams/2"
      def belongs_to(name, attrs={}) # {{{
        @her_relationships ||= {}
        (@her_relationships[:belongs_to] ||= []) << attrs.merge(:name => name)
        collection_path = @her_collection_path

        define_method(name) do
          return @data[name] if @data.include?(name) # Do not fetch from API again if we have it in @data
          self.class.get_resource("#{Object.const_get(name.to_s.classify).collection_path}/#{@data["#{name}_id".to_sym]}")
        end
      end # }}}
    end
  end
end
