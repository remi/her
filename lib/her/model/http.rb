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

      # Make a GET request and return the parsed JSON response (not mapped to objects)
      #
      # @example
      #   User.get "/users/1"
      def get(path, attrs={}, &block) # {{{
        request(attrs.merge(:_method => :get, :_path => path), &block)
      end # }}}

      # Make a POST request and return the parsed JSON response (not mapped to objects)
      #
      # @example
      #   User.post "/users", :fullname => "G.O.B. Bluth"
      def post(path, attrs={}, &block) # {{{
        request(attrs.merge(:_method => :post, :_path => path), &block)
      end # }}}

      # Make a PUT request and return the parsed JSON response (not mapped to objects)
      #
      # @example
      #   User.put "/users/1", :email => "gob@bluthcompany.com"
      def put(path, attrs={}, &block) # {{{
        request(attrs.merge(:_method => :put, :_path => path), &block)
      end # }}}

      # Make a DELETE request and return the parsed JSON response (not mapped to objects)
      #
      # @example
      #   User.delete "/users/1"
      def delete(path, attrs={}, &block) # {{{
        request(attrs.merge(:_method => :delete, :_path => path), &block)
      end # }}}
    end
  end
end
