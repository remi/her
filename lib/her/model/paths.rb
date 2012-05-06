module Her
  module Model
    module Paths
      # Defines a custom collection path for the resource
      #
      # @example
      #  class User
      #    include Her::Model
      #    collection_path "/users"
      #  end
      def collection_path(path=nil) # {{{
        return @her_collection_path unless path
        @her_resource_path = "#{path}/:id"
        @her_collection_path = path
      end # }}}

      # Defines a custom resource path for the resource
      #
      # @example
      #  class User
      #    include Her::Model
      #    resource_path "/users/:id"
      #  end
      def resource_path(path=nil) # {{{
        return @her_resource_path unless path
        @her_resource_path = path
      end # }}}

      # Return a custom path based on the collection path and variable parameters
      #
      # @example
      #   class User
      #     include Her::Model
      #     collection_path "/utilisateurs"
      #   end
      #
      #   User.all # Fetched via GET /utilisateurs
      def build_request_path(path=nil, parameters={}) # {{{
        unless path.is_a?(String)
          parameters = path || {}
          path = parameters.include?(:id) ? @her_resource_path : @her_collection_path
        end
        path.gsub(/:([\w_]+)/) do
          # Look for :key or :_key, otherwise raise an exception
          parameters[$1.to_sym] || parameters["_#{$1}".to_sym] || raise(Her::Errors::PathError.new("Missing :_#{$1} parameter to build the request path (#{path})."))
        end
      end # }}}

      # Return a path based on the collection path and a resource data
      #
      # @example
      #   class User
      #     include Her::Model
      #     collection_path "/utilisateurs"
      #   end
      #
      #   User.find(1) # Fetched via GET /utilisateurs/1
      def request_path # {{{
        self.class.build_request_path(@data)
      end # }}}
    end
  end
end
