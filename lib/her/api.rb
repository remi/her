require 'her/api/connection'

module Her
  # This class is where all HTTP requests are made. Before using Her, you must configure it
  # so it knows where to make those requests. In Rails, this is usually done in `config/initializers/her.rb`:
  class API
    # @private
    attr_reader :connection, :options

    # Setup a default API connection that will be used for all models. Accepted arguments and options are the same as {API#initialize}.
    def self.setup(opts={}, &block)
      @default_api = new(opts, &block)
    end

    # Setup an API connection.
    #
    # @param [Hash] opts Faraday::Connection options
    # @param [Block] &blk The middleware stack block
    # @option opts [String] :url The main HTTP API root (eg. `https://api.example.com`)
    # @option opts [String] :ssl A hash containing [SSL options](https://github.com/technoweenie/faraday/wiki/Setting-up-SSL-certificates)
    #
    # @example Setting up the default API connection
    #   Her::API.setup :url => "https://api.example.com" do |connection|
    #     connection.use Faraday::Request::UrlEncoded
    #     connection.use Her::Middleware::DefaultParseJSON
    #     connection.use Faraday::Adapter::NetHttp
    #   end
    #
    # @example Setting up a single API connection
    #   my_api = Her::API.new :url => "https://api.example.com" do |connection|
    #     connection.use Faraday::Request::UrlEncoded
    #     connection.use Her::Middleware::DefaultParseJSON
    #     connection.use Faraday::Adapter::NetHttp
    #   end
    #
    #   class User
    #     include Her::Model
    #     use_api my_api
    #   end
    def initialize(opts={}, &blk)
      @connection = Connection.new(@options = opts) { |connection| yield connection if block_given? }
    end

    # Forward all request to the Faraday connection
    # @private
    def request(opts={})
      @connection.request(opts)
    end

    private
    # @private
    def self.default_api
      @default_api
    end
  end
end
