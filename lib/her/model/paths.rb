module Her
  module Model
    module Paths
      # Defines a custom collection path for the resource
      #
      # @example
      #  class User
      #    include Her::Model
      #    collection_path "users"
      #  end
      def collection_path(path=nil) # {{{
        return @her_collection_path unless path
        @her_collection_path = path
      end # }}}

      # Return a custom path based on the collection path and variable parameters
      #
      # @example
      #   class User
      #     include Her::Model
      #     collection_path "/utilisateurs/:id"
      #   end
      #
      #   User.find(1) # Fetched via GET /utilisateurs/1
      def build_request_path(parameters) # {{{
        "NOPE"
      end # }}}

      # Return a path based on the collection path and a resource data
      def request_path # {{{
        "WUT"
      end # }}}
    end
  end
end
