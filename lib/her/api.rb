module Her
  # This class is where all HTTP requests are made. Before using Her, you must configure it
  # so it knows where to make those requests. In Rails, this is usually done in `config/initializers/her.rb`:
  #
  # @example
  #   $my_api = Her::API.new
  #   $my_api.setup :base_uri => "https://api.example.com"
  class API
    # @private
    attr_reader :base_uri, :middleware

    # Setup a default API connection
    def self.setup(attrs={}) # {{{
      @@default_api = new
      @@default_api.setup(attrs)
    end # }}}

    # @private
    def self.default_api(attrs={}) # {{{
      defined?(@@default_api) ? @@default_api : nil
    end # }}}

    # @private
    def self.default_middleware # {{{
      [Her::Middleware::DefaultParseJSON, Faraday::Request::UrlEncoded, Faraday::Adapter::NetHttp]
    end # }}}

    # Setup the API connection
    #
    # @example A custom parse middleware
    #   module MyAPI
    #     class ParseResponse
    #       def on_complete(env)
    #         json = JSON.parse(env[:body], :symbolize_names => true)
    #         {
    #           :data => json,
    #           :errors => json[:errors] || [],
    #           :metadata => json[:metadata] || {},
    #         }
    #       end
    #     end
    #   end
    #   Her::API.setup :base_uri => "https://api.example.com", :parse_middleware => MyAPI::ParseResponse
    def setup(attrs={}) # {{{
      @base_uri = attrs[:base_uri]
      @middleware = Her::API.default_middleware

      @middleware = [attrs[:middleware]] if attrs[:middleware]
      @middleware = [attrs[:add_middleware]] + @middleware if attrs[:add_middleware]
      @middleware = [attrs[:parse_middleware]] + @middleware.reject { |item| item == Her::Middleware::DefaultParseJSON } if attrs[:parse_middleware]

      @middleware.flatten!
      middleware = @middleware
      @connection = Faraday.new(:url => @base_uri) do |builder|
        middleware.each { |m| builder.use(m) }
      end
    end # }}}

    # Define a custom parsing procedure. The procedure is passed the response object and is
    # expected to return a hash with three keys: a main data Hash, an errors Array
    # and a metadata Hash.
    #
    # @example

    # Make an HTTP request to the API
    def request(attrs={}) # {{{
      method = attrs.delete(:_method)
      path = attrs.delete(:_path)
      response = @connection.send method do |request|
        if method == :get
          # For GET requests, treat additional parameters as querystring data
          request.url path, attrs
        else
          # For POST, PUT and DELETE requests, treat additional parameters as request body
          request.url path
          request.body = attrs
        end
      end
      response.env[:body]
    end # }}}
  end
end
