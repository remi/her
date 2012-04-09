module Her
  # This class is where all HTTP requests are made. Before using Her, you must configure it
  # so it knows where to make those requests. In Rails, this is usually done in `config/initializers/her.rb`:
  #
  # @example
  #   $my_api = Her::API.new
  #   $my_api.setup :base_uri => "https://api.example.com"
  class API
    # @private
    attr_reader :base_uri, :parse_with

    # Setup a default API connection
    def self.setup(attrs={}) # {{{
      @@default_api = new
      @@default_api.setup(attrs)
    end # }}}

    # @private
    def self.default_api(attrs={}) # {{{
      defined?(@@default_api) ? @@default_api : nil
    end # }}}

    # Setup the API connection
    def setup(attrs={}) # {{{
      @base_uri = attrs[:base_uri]
      @parse_with = lambda do |response|
        json = JSON.parse(response.body, :symbolize_names => true)
        {
          :resource => json[:data],
          :errors => json[:errors],
          :metadata => json[:metadata],
        }
      end
      @connection = Faraday.new(:url => @base_uri) do |builder|
        builder.request  :url_encoded
        builder.adapter  :net_http
      end
    end # }}}

    # Define a custom parsing procedure. The procedure is passed the response object and is
    # expected to return a hash with three keys: a main resource Hash, an errors Array
    # and a metadata Hash.
    #
    # @example
    #   $my_api.parse_with do |response|
    #     json = JSON.parse(response.body)
    #     { :resource => json[:data], :errors => json[:errors], :metadata => json[:metdata] }
    #   end
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
      # TODO Here, we would probably look for hooks that modify the request before calling the API
      @connection.send(attrs[:method], attrs[:path])
    end # }}}

    # Parse the HTTP response
    def parse(response) # {{{
      @parse_with.call(response)
    end # }}}
  end
end
