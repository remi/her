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
            name = relationship[:name]
            klass = self.nearby_class(relationship[:class_name])
            next if !data.include?(name) or data[name].nil?
            data[name] = case type
              when :has_many
                Her::Model::ORM.initialize_collection(klass, :data => data[name])
              when :has_one, :belongs_to
                klass.new(data[name])
              else
                nil
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
        attrs = {
          :class_name => name.to_s.classify,
          :name => name,
          :path => "/#{name}"
        }.merge(attrs)
        (@her_relationships[:has_many] ||= []) << attrs

        define_method(name) do
          klass = self.class.nearby_class(attrs[:class_name])
          @data[name] ||= klass.get_collection("#{self.class.build_request_path(:id => id)}#{attrs[:path]}")
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
        attrs = {
          :class_name => name.to_s.classify,
          :name => name,
          :path => "/#{name}"
        }.merge(attrs)
        (@her_relationships[:has_one] ||= []) << attrs

        define_method(name) do
          klass = self.class.nearby_class(attrs[:class_name])
          @data[name] ||= klass.get_resource("#{self.class.build_request_path(:id => id)}#{attrs[:path]}")
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
      #     belongs_to :team, :class_name => "Group"
      #   end
      #
      #   class Group
      #     include Her::API
      #   end
      #
      #   @user = User.find(1)
      #   @user.team # => #<Team(teams/2) id=2 name="Developers">
      #   # Fetched via GET "/teams/2"
      def belongs_to(name, attrs={}) # {{{
        @her_relationships ||= {}
        attrs = {
          :class_name => name.to_s.classify,
          :name => name,
          :foreign_key => "#{name}_id",
          :path => "/#{name.to_s.pluralize}/:id"
        }.merge(attrs)
        (@her_relationships[:belongs_to] ||= []) << attrs

      # @private
      def relationship_accessor(type, attrs) # {{{
        name = attrs[:name]
        class_name = attrs[:class_name]
        define_method(name) do
          klass = self.class.nearby_class(attrs[:class_name])
          @data[name] ||= klass.get_resource("#{klass.build_request_path(attrs[:path], :id => @data[attrs[:foreign_key].to_sym])}")
        end
      end # }}}
    end
  end
end
