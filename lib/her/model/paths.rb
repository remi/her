module Her
  module Model
    module Paths
      extend ActiveSupport::Concern
      # Return a path based on the collection path and a resource data
      #
      # @example
      #   class User
      #     include Her::Model
      #     collection_path "/utilisateurs"
      #   end
      #
      #   User.find(1) # Fetched via GET /utilisateurs/1
      #
      # @param [Hash] params An optional set of additional parameters for
      #   path construction. These will not override attributes of the resource.
      def request_path(params = {})
        self.class.build_request_path(params.merge(attributes.dup))
      end

      module ClassMethods

        # Define the primary key field that will be used to find and save records
        #
        # @example
        #  class User
        #    include Her::Model
        #    primary_key 'UserId'
        #  end
        #
        # @param [Symbol] field
        def primary_key(field = nil)
          return @her_primary_key if field.nil?
          @her_primary_key = field.to_sym
        end

        # Defines a custom collection path for the resource
        #
        # @example
        #  class User
        #    include Her::Model
        #    collection_path "/users"
        #  end
        def collection_path(path=nil)
          @her_collection_path ||= begin
            superclass.collection_path.dup if superclass.respond_to?(:collection_path)
          end

          return @her_collection_path unless path
          @her_resource_path = "#{path}/:id"
          @her_collection_path = path
        end

        # Defines a custom resource path for the resource
        #
        # @example
        #  class User
        #    include Her::Model
        #    resource_path "/users/:id"
        #  end
        #
        # Note that, if used in combination with resource_path, you may specify
        # either the real primary key or the string ':id'. For example:
        #
        # @example
        #  class User
        #    include Her::Model
        #    primary_key 'user_id'
        #
        #    # This works because we'll have a user_id attribute
        #    resource_path '/users/:user_id'
        #
        #    # This works because we replace :id with :user_id
        #    resource_path '/users/:id'
        #  end
        #
        def resource_path(path=nil)
          @her_resource_path ||= begin
            superclass.resource_path.dup if superclass.respond_to?(:resource_path)
          end

          return @her_resource_path unless path
          @her_resource_path = path
        end

        # Return a custom path based on the collection path and variable parameters
        #
        # @example
        #   class User
        #     include Her::Model
        #     collection_path "/utilisateurs"
        #   end
        #
        #   User.all # Fetched via GET /utilisateurs
        def build_request_path(path=nil, parameters={})
          unless path.is_a?(String)
            parameters = path || {}
            path =
              if parameters.include?(primary_key) && parameters[primary_key]
                resource_path.dup
              else
                collection_path.dup
              end

            # Replace :id with our actual primary key
            path.gsub!(/(\A|\/):id(\Z|\/)/, "\\1:#{primary_key}\\2")
          end

          path.gsub(/:([\w_]+)/) do
            # Look for :key or :_key, otherwise raise an exception
            parameters.delete($1.to_sym) || parameters.delete("_#{$1}".to_sym) || raise(Her::Errors::PathError, "Missing :_#{$1} parameter to build the request path. Path is `#{path}`. Parameters are `#{parameters.inspect}`.")
          end
        end

        # Return or change the value of `root_element`
        def root_element(value=nil)
          return @root_element if value.nil?
          @root_element = value
        end
      end
    end
  end
end
