module Her
  # This class is where all HTTP requests are made. Before using Her, you must configure it
  # so it knows where to make those requests. In Rails, this is usually done in `config/initializers/her.rb`:
  class API
    # @private
    attr_reader :base_uri, :middleware

    # Setup a default API connection. Accepted arguments and options are the same as {API#setup}.
    def self.setup(attrs={}) # {{{
      @@default_api = new
      @@default_api.setup(attrs)
    end # }}}

    # Setup the API connection.
    #
    # @param [Hash] attrs the options to create a message with
    # @option attrs [String] :base_uri The main HTTP API root (eg. `https://api.example.com`)
    # @option attrs [Array, Class] :middleware A list of the only middleware Her will use
    # @option attrs [Array, Class] :add_middleware A list of middleware to add to Her’s default middleware
    # @option attrs [Class] :parse_middleware A middleware that will replace {Her::Middleware::FirstLevelParseJSON} to parse the received JSON
    #
    # @example Setting up the default API connection
    #   Her::API.setup :base_uri => "https://api.example"
    #
    # @example A custom middleware added to the default list
    #   class MyAuthentication < Faraday::Middleware
    #     def call(env)
    #       env[:request_headers]["X-API-Token"] = "bb2b2dd75413d32c1ac421d39e95b978d1819ff611f68fc2fdd5c8b9c7331192"
    #       @all.call(env)
    #     end
    #   end
    #   Her::API.setup :base_uri => "https://api.example.com", :add_middleware => [MyAuthentication]
    #
    # @example A custom parse middleware
    #   class MyCustomParser < Faraday::Response::Middleware
    #     def on_complete(env)
    #       json = JSON.parse(env[:body], :symbolize_names => true)
    #       errors = json.delete(:errors) || []
    #       metadata = json.delete(:metadata) || []
    #       env[:body] = { :data => json, :errors => errors, :metadata => metadata }
    #     end
    #   end
    #   Her::API.setup :base_uri => "https://api.example.com", :parse_middleware => MyCustomParser
    def setup(attrs={}) # {{{
      @base_uri = attrs[:base_uri]
      @middleware = Her::API.default_middleware

      @middleware = [attrs[:middleware]] if attrs[:middleware]
      @middleware = [attrs[:add_middleware]] + @middleware if attrs[:add_middleware]
      @middleware = [attrs[:parse_middleware]] + @middleware.reject { |item| item == Her::Middleware::FirstLevelParseJSON } if attrs[:parse_middleware]

      @middleware.flatten!
      middleware = @middleware
      @connection = Faraday.new(:url => @base_uri) do |builder|
        middleware.each do |item|
          klass = item.is_a?(Hash) ? item.keys.first : item
          args = item.is_a?(Hash) ? item.values.first : nil
          if args
            builder.use klass, args
          else
            builder.use klass
          end
        end
      end
    end # }}}

    # Define a custom parsing procedure. The procedure is passed the response object and is
    # expected to return a hash with three keys: a main data Hash, an errors Array
    # and a metadata Hash.
    #
    # @private
    def request(attrs={}) # {{{
      method = attrs.delete(:_method)
      path = attrs.delete(:_path)
      attrs.delete_if { |key, value| key =~ /^_/ } # Remove all internal parameters
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

    private
    # @private
    def self.default_api(attrs={}) # {{{
      defined?(@@default_api) ? @@default_api : nil
    end # }}}

    # @private
    def self.default_middleware # {{{
      [Her::Middleware::FirstLevelParseJSON, Faraday::Request::UrlEncoded, Faraday::Adapter::NetHttp]
    end # }}}
  end
end
