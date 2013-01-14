module Her
  # This class is where all HTTP requests are made. Before using Her, you must configure it
  # so it knows where to make those requests. In Rails, this is usually done in `config/initializers/her.rb`:
  class API
    # @private
    attr_reader :base_uri, :connection, :options

    # Setup a default API connection. Accepted arguments and options are the same as {API#setup}.
    def self.setup(attrs={}, &block)
      @@default_api = new
      @@default_api.setup(attrs, &block)
    end

    # Setup the API connection.
    #
    # @param [Hash] attrs the Faraday options
    # @option attrs [String] :url The main HTTP API root (eg. `https://api.example.com`)
    # @option attrs [String] :ssl A hash containing [SSL options](https://github.com/technoweenie/faraday/wiki/Setting-up-SSL-certificates)
    #
    # @return Faraday::Connection
    #
    # @example Setting up the default API connection
    #   Her::API.setup :url => "https://api.example"
    #
    # @example A custom middleware added to the default list
    #   class MyAuthentication < Faraday::Middleware
    #     def call(env)
    #       env[:request_headers]["X-API-Token"] = "bb2b2dd75413d32c1ac421d39e95b978d1819ff611f68fc2fdd5c8b9c7331192"
    #       @all.call(env)
    #     end
    #   end
    #   Her::API.setup :url => "https://api.example.com" do |connection|
    #     connection.use Faraday::Request::UrlEncoded
    #     connection.use Her::Middleware::DefaultParseJSON
    #     connection.use Faraday::Adapter::NetHttp
    #   end
    #
    # @example A custom parse middleware
    #   class MyCustomParser < Faraday::Response::Middleware
    #     def on_complete(env)
    #       json = JSON.parse(env[:body], :symbolize_names => true)
    #       errors = json.delete(:errors) || {}
    #       metadata = json.delete(:metadata) || []
    #       env[:body] = { :data => json, :errors => errors, :metadata => metadata }
    #     end
    #   end
    #   Her::API.setup :url => "https://api.example.com" do |connection|
    #     connection.use Faraday::Request::UrlEncoded
    #     connection.use MyCustomParser
    #     connection.use Faraday::Adapter::NetHttp
    #   end
    def setup(attrs={})
      attrs[:url] = attrs.delete(:base_uri) if attrs.include?(:base_uri) # Support legacy :base_uri option
      @base_uri = attrs[:url]
      @options = attrs
      @connection = Faraday.new(@options) do |connection|
        yield connection if block_given?
      end
    end

    # Define a custom parsing procedure. The procedure is passed the response object and is
    # expected to return a hash with three keys: a main data Hash, an errors Hash
    # and a metadata Hash.
    #
    # @private
    def request(attrs={})
      method = attrs.delete(:_method)
      path = attrs.delete(:_path)
      headers = attrs.delete(:_headers)
      attrs.delete_if { |key, value| key.to_s =~ /^_/ } # Remove all internal parameters
      response = @connection.send method do |request|
        request.headers.merge!(headers) if headers
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
    end

    private
    # @private
    def self.default_api(attrs={})
      defined?(@@default_api) ? @@default_api : nil
    end
  end
end
