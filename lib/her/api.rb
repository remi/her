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
    end # }}}

    # Make an HTTP request to the API
    def self.request(attrs={}) # {{{
      p "base_uri is #{@base_uri}"
      p "request attributes are #{attrs}"
    end # }}}
  end
end
