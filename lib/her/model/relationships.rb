module Her
  module Model
    # This module adds relationships to models
    module Relationships
      extend ActiveSupport::Concern

      # Returns true if the model has a relationship_name relationship, false otherwise.
      def has_relationship?(relationship_name)
        relationships = self.class.relationships.values.flatten.map { |r| r[:name] }
        relationships.include?(relationship_name)
      end

      # Returns the resource/collection corresponding to the relationship_name relationship.
      def get_relationship(relationship_name)
        send(relationship_name) if has_relationship?(relationship_name)
      end

      module ClassMethods
        # Return @her_relationships, lazily initialized with copy of the
        # superclass' her_relationships, or an empty hash.
        #
        # @private
        def relationships
          @her_relationships ||= begin
            if superclass.respond_to?(:relationships)
              superclass.relationships.dup
            else
              {}
            end
          end
        end

        # Parse relationships data after initializing a new object
        #
        # @private
        def parse_relationships(data)
          relationships.each_pair do |type, definitions|
            definitions.each do |relationship|
              name = relationship[:name]
              next unless data[name]
              klass = self.nearby_class(relationship[:class_name])
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
        end

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
        def has_many(name, attrs={})
          attrs = {
            :class_name     => name.to_s.classify,
            :name           => name,
            :path           => "/#{name}",
            :inverse_of => nil
          }.merge(attrs)
          (relationships[:has_many] ||= []) << attrs

          define_method(name) do |*method_attrs|
            method_attrs = method_attrs[0] || {}
            klass = self.class.nearby_class(attrs[:class_name])
            if method_attrs.any?
              @data[name] = klass.get_collection("#{self.class.build_request_path(method_attrs.merge(:id => id))}#{attrs[:path]}")
            else
              @data[name] ||= klass.get_collection("#{self.class.build_request_path(:id => id)}#{attrs[:path]}")
            end

            inverse_of = if attrs[:inverse_of]
                               attrs[:inverse_of]
                            else
                             self.class.name.split('::').last.tableize.singularize
                           end
            @data[name].each do |entry|
              entry.send("#{inverse_of}=", self)
            end

            @data[name]
          end
        end

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
        def has_one(name, attrs={})
          attrs = {
            :class_name => name.to_s.classify,
            :name => name,
            :path => "/#{name}"
          }.merge(attrs)
          (relationships[:has_one] ||= []) << attrs

          define_method(name) do |*method_attrs|
            method_attrs = method_attrs[0] || {}
            klass = self.class.nearby_class(attrs[:class_name])
            if method_attrs.any?
              klass.get_resource("#{self.class.build_request_path(method_attrs.merge(:id => id))}#{attrs[:path]}")
            else
              @data[name] ||= klass.get_resource("#{self.class.build_request_path(:id => id)}#{attrs[:path]}")
            end
          end
        end

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
        def belongs_to(name, attrs={})
          attrs = {
            :class_name => name.to_s.classify,
            :name => name,
            :foreign_key => "#{name}_id",
            :path => "/#{name.to_s.pluralize}/:id"
          }.merge(attrs)
          (relationships[:belongs_to] ||= []) << attrs

          define_method(name) do |*method_attrs|
            method_attrs = method_attrs[0] || {}
            klass = self.class.nearby_class(attrs[:class_name])
            if method_attrs.any?
              klass.get_resource("#{klass.build_request_path(method_attrs.merge(:id => @data[attrs[:foreign_key].to_sym]))}")
            else
              @data[name] ||= klass.get_resource("#{klass.build_request_path(:id => @data[attrs[:foreign_key].to_sym])}")
            end
          end
        end

        # @private
        def relationship_accessor(type, attrs)
          name = attrs[:name]
          class_name = attrs[:class_name]
          define_method(name) do
            klass = self.class.nearby_class(attrs[:class_name])
            @data[name] ||= klass.get_resource("#{klass.build_request_path(attrs[:path], :id => @data[attrs[:foreign_key].to_sym])}")
          end
        end
      end
    end
  end
end
