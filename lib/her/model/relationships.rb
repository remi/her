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
            class_name = relationship[:class_name]
            next unless data.include?(name)
            data[name] = case type
              when :has_many
                Her::Model::ORM.initialize_collection(class_name, data[name])
              when :has_one, :belongs_to
                Object.const_get(class_name).new(data[name])
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
        attrs = { :class_name => name.to_s.classify, :name => name }.merge(attrs)
        define_relationship(:has_many, attrs)
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
        attrs = { :class_name => name.to_s.classify, :name => name }.merge(attrs)
        define_relationship(:has_one, attrs)
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
        attrs = { :class_name => name.to_s.classify, :name => name, :foreign_key => "#{name}_id" }.merge(attrs)
        define_relationship(:belongs_to, attrs)
      end # }}}

      private
      # @private
      def define_relationship(type, attrs) # {{{
        @her_relationships ||= {}
        (@her_relationships[type] ||= []) << attrs
        relationship_accessor(type, attrs)
      end # }}}

      # @private
      def relationship_accessor(type, attrs) # {{{
        name = attrs[:name]
        class_name = attrs[:class_name]
        define_method(name) do
          return @data[name] if @data.include?(name)

          klass = Object.const_get(class_name)
          path = self.class.build_request_path(:id => id)
          @data[name] = case type
            when :belongs_to
              foreign_key = attrs[:foreign_key].to_sym
              klass.get_resource("#{klass.build_request_path(:id => @data[foreign_key])}")
            when :has_many
              klass.get_collection("#{path}/#{name.to_s.pluralize}")
            when :has_one
              klass.get_resource("#{path}/#{name.to_s.singularize}")
          end
        end
      end # }}}
    end
  end
end
