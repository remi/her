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

      # Define an *has_many* relationship for the resource
      #
      # * `User.has_many :comments` is used to check if the "user" JSON
      #   resource we receive has a `comments` key and map it to an array
      #   of Comment objects
      # * `User.has_many :comments` creates a User.comments method to would
      #   make an extra HTTP request (to `/users/:id/comments`) if there was no "comments" key
      def has_many(name, attrs={}) # {{{
        @her_relationships ||= {}
        (@her_relationships[:has_many] ||= []) << attrs.merge(:name => name)
        collection_path = @her_collection_path

        define_method(name) do
          return @data[name] if @data.include?(name) # Do not fetch from API again if we have it in @data
          self.class.get_collection("#{collection_path}/#{id}/#{Object.const_get(name.to_s.classify).collection_path}")
        end
      end # }}}

      # Define an *has_one* relationship for the resource
      #
      # * `User.has_one :category` is used to check if the "category" JSON
      #   resource we receive has a `category` key and map it to a Category object
      # * `User.has_one :category` creates a User.category method to would
      #   make an extra HTTP request (to `/users/category`) if there was no "category" key
      def has_one(name, attrs={}) # {{{
        @her_relationships ||= {}
        (@her_relationships[:has_one] ||= []) << attrs.merge(:name => name)
        collection_path = @her_collection_path

        define_method(name) do
          return @data[name] if @data.include?(name) # Do not fetch from API again if we have it in @data
          self.class.get_resource("#{collection_path}/#{id}/#{Object.const_get(name.to_s.classify).item_path}")
        end
      end # }}}

      # Define a *belongs_to* relationship for the resource
      #
      # * `User.belongs_to :organization` is used to check if the "organization" JSON
      #   resource we receive has a `organization` key and map it to an Organization object
      # * `User.belongs_to :organization` creates a User.organization method to would
      #   make an extra HTTP request (to `/organizations/:organization_id`) if there was no "organization" key
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
