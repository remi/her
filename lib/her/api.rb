module Her
  # This class is where all HTTP requests are made. Before using Her, you must configure it
  # so it knows where to make those requests. In Rails, this is usually done in `config/initializers/her.rb`:
  #
  # @example
  #   $my_api = Her::API.new
  #   $my_api.setup :base_uri => "https://api.example.com"
  class API
    attr_reader :base_uri, :parse_with

    # Setup the API connection
    def setup(attrs={}) # {{{
      @base_uri = attrs[:base_uri]
      @parse_with = lambda do |response|
        json = JSON.parse(response.body, :symbolize_names => true)
        [json[:data], json[:errors], json[:metadata]]
      end
    end # }}}

    # Define a custom parsing procedure. The procedure is expected to return an array
    # of three elements: the main data, the errors and the metadata.
    def parse_with(&block) # {{{
      @custom_parsing_block = true
      @parse_with = block
    end # }}}

    # Return whether a custom parsing block has been defined
    def custom_parsing_block? # {{{
      @custom_parsing_block
    end # }}}

    # Make an HTTP request to the API
    def request(attrs={}) # {{{
      p "base_uri is #{@base_uri}"
      p "request attributes are #{attrs}"
    end # }}}

    # Parse the HTTP response
    def parse(response) # {{{
      @parse_with.call(response)
    end # }}}
  end
end
