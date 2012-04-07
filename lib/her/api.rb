module Her
  # This class is where all HTTP requests are made. Before using Her, you must configure it
  # so it knows where to make those requests. In Rails, this is done in `config/initializers/her.rb`:
  #
  # @example
  #   Her::API.setup :base_uri => "https://api.example.com"
  class API
    # Setup the API connection
    def self.setup(attrs={}) # {{{
      @base_uri = attrs[:base_uri]
      @parse_with = lambda do |response|
        json = JSON.parse(response.body, :symbolize_names => true)
        [json[:data], json[:errors], json[:metadata]]
      end
    end # }}}

    # Define a custom parsing procedure. The procedure is expected to return an array
    # of three elements: the main data, the errors and the metadata.
    def self.parse_with(&block) # {{{
      @parse_with = block
    end # }}}

    # Make an HTTP request to the API
    def self.request(attrs={}) # {{{
      p "base_uri is #{@base_uri}"
      p "request attributes are #{attrs}"
    end # }}}

    # Parse the HTTP response
    def self.parse(response) # {{{
      @parse_with.call(response)
    end # }}}
  end
end
