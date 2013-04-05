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
        # Return @her_associations, lazily initialized with copy of the
        # superclass' her_associations, or an empty hash.
        #
        # @private
        def associations
          @her_associations ||= begin
            if superclass.respond_to?(:associations)
              superclass.associations.dup
            else
              {}
            end
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

              klass = self.nearby_class(association[:class_name])
              name = association[:name]

              data[name] = case type
                when :has_many
                  Her::Model::ORM.initialize_collection(klass, :data => data[data_key])
                when :has_one, :belongs_to
                  klass.new(data[data_key])
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
            :data_key       => name,
            :path           => "/#{name}",
            :inverse_of => nil
          }.merge(attrs)
          (associations[:has_many] ||= []) << attrs

          define_method(name) do |*method_attrs|
            method_attrs = method_attrs[0] || {}
            klass = self.class.nearby_class(attrs[:class_name])

            return Her::Collection.new if @attributes.include?(name) && @attributes[name].empty? && method_attrs.empty?

            if @attributes[name].blank? || method_attrs.any?
              path = begin
                request_path(method_attrs)
              rescue Her::Errors::PathError
                return nil
              end

              @attributes[name] = klass.get_collection("#{path}#{attrs[:path]}", method_attrs)
            end

            inverse_of = attrs[:inverse_of] || self.class.name.split('::').last.tableize.singularize

            @attributes[name].each do |entry|
              entry.send("#{inverse_of}=", self)
            end

            @attributes[name]
          end
        end

        # Define an *has_one* association.
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
            :data_key => name,
            :path => "/#{name}"
          }.merge(attrs)
          (associations[:has_one] ||= []) << attrs

          define_method(name) do |*method_attrs|
            method_attrs = method_attrs[0] || {}
            klass = self.class.nearby_class(attrs[:class_name])

            return nil if @attributes.include?(name) && @attributes[name].nil? && method_attrs.empty?

            if @attributes[name].blank? || method_attrs.any?
              path = begin
                request_path(method_attrs)
              rescue Her::Errors::PathError
                return nil
              end

              @attributes[name] = klass.get_resource("#{path}#{attrs[:path]}", method_attrs)
            end

            @attributes[name]
          end
        end

        # Define a *belongs_to* association.
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
            :data_key => name,
            :foreign_key => "#{name}_id",
            :path => "/#{name.to_s.pluralize}/:id"
          }.merge(attrs)
          (associations[:belongs_to] ||= []) << attrs

          define_method(name) do |*method_attrs|
            method_attrs = method_attrs[0] || {}
            klass = self.class.nearby_class(attrs[:class_name])

            return nil if @attributes.include?(name) && @attributes[name].nil? && method_attrs.empty?

            if @attributes[name].blank? || method_attrs.any?
              path = begin
                klass.build_request_path(@attributes.merge(method_attrs.merge(klass.primary_key => @attributes[attrs[:foreign_key].to_sym])))
              rescue Her::Errors::PathError
                return nil
              end

              @attributes[name] = klass.get_resource("#{path}", method_attrs)
            end

            @attributes[name]
          end
        end
      end
    end
  end
end
