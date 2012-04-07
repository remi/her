module Her
  module Model
    # This module interacts with Her::API to fetch HTTP data
    module HTTP
      # Main wrapper around Her::API
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
