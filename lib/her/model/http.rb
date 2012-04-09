module Her
  module Model
    # This module interacts with Her::API to fetch HTTP data
    module HTTP
      # Link a model with a Her::API object
      def uses_api(api) # {{{
        @her_api = api
      end # }}}

      # Defines a custom collection path for the resource
      #
      # @example
      #  class User
      #    include Her::Model
      #    uses_api $example_api
      #    collection_path "users"
      #  end
      def collection_path(path=nil) # {{{
        return @her_collection_path unless path
        @her_collection_path = path
      end # }}}

      # Main request wrapper around Her::API. Used to make custom request to the API.
      # @private
      def request(attrs={}, &block) # {{{
        response = @her_api.request(attrs)
        yield @her_api.parse(response)
      end # }}}

      # Make a GET request and return the parsed JSON response
      #
      # @example
      #   User.get "/users/foo"
      def get(path, attrs={}, &block) # {{{
        request(attrs.merge(:_method => :get, :_path => path), &block)
      end # }}}
    end
  end
end
