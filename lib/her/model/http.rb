module Her
  module Model
    # This module interacts with Her::API to fetch HTTP data
    module HTTP
      # Link a model with a Her::API object
      def uses_api(api) # {{{
        @her_api = api
      end # }}}

      # Main request wrapper around Her::API. Used to make custom request to the API.
      #
      # @private
      def request(attrs={}) # {{{
        p "relationships are"
        p @her_relationships
        response = @her_api.request(attrs)
        @her_api.parse(response)
      end # }}}

      # Make a GET request and return the parsed JSON response
      def get(path, attrs={}) # {{{
        request attrs.merge(:path => path)
      end # }}}
    end
  end
end
