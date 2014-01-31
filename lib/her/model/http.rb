module Her
  module Model
    # This module interacts with Her::API to fetch HTTP data
    module HTTP
      extend ActiveSupport::Concern
      METHODS = [:get, :post, :put, :patch, :delete]

      # For each HTTP method, define these class methods:
      #
      # - <method>(path, params)
      # - <method>_raw(path, params, &block)
      # - <method>_collection(path, params, &block)
      # - <method>_resource(path, params, &block)
      # - custom_<method>(*paths)
      #
      # @example
      #   class User
      #     include Her::Model
      #     custom_get :active
      #   end
      #
      #   User.get(:popular) # GET "/users/popular"
      #   User.active # GET "/users/active"
      module ClassMethods
        # Change which API the model will use to make its HTTP requests
        #
        # @example
        #   secondary_api = Her::API.new :url => "https://api.example" do |connection|
        #     connection.use Faraday::Request::UrlEncoded
        #     connection.use Her::Middleware::DefaultParseJSON
        #   end
        #
        #   class User
        #     include Her::Model
        #     use_api secondary_api
        #   end
        def use_api(value = nil)
          @_her_use_api ||= begin
            superclass.use_api if superclass.respond_to?(:use_api)
          end

          unless value
            return (@_her_use_api.respond_to? :call) ? @_her_use_api.call : @_her_use_api
          end

          @_her_use_api = value
        end

        alias her_api use_api
        alias uses_api use_api

        # Main request wrapper around Her::API. Used to make custom request to the API.
        #
        # @private
        def request(params={})
          request = her_api.request(params)

          if block_given?
            yield request[:parsed_data], request[:response]
          else
            { :parsed_data => request[:parsed_data], :response => request[:response] }
          end
        end

        METHODS.each do |method|
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{method}(path, params={})
              path = build_request_path_from_string_or_symbol(path, params)
              params = to_params(params) unless #{method.to_sym.inspect} == :get
              send(:'#{method}_raw', path, params) do |parsed_data, response|
                if parsed_data[:data].is_a?(Array) || active_model_serializers_format? || json_api_format?
                  new_collection(parsed_data)
                else
                  new(parse(parsed_data[:data]).merge :_metadata => parsed_data[:metadata], :_errors => parsed_data[:errors])
                end
              end
            end

            def #{method}_raw(path, params={}, &block)
              path = build_request_path_from_string_or_symbol(path, params)
              request(params.merge(:_method => #{method.to_sym.inspect}, :_path => path), &block)
            end

            def #{method}_collection(path, params={})
              path = build_request_path_from_string_or_symbol(path, params)
              send(:'#{method}_raw', build_request_path_from_string_or_symbol(path, params), params) do |parsed_data, response|
                new_collection(parsed_data)
              end
            end

            def #{method}_resource(path, params={})
              path = build_request_path_from_string_or_symbol(path, params)
              send(:"#{method}_raw", path, params) do |parsed_data, response|
                new(parse(parsed_data[:data]).merge :_metadata => parsed_data[:metadata], :_errors => parsed_data[:errors])
              end
            end

            def custom_#{method}(*paths)
              metaclass = (class << self; self; end)
              opts = paths.last.is_a?(Hash) ? paths.pop : Hash.new

              paths.each do |path|
                metaclass.send(:define_method, path) do |*params|
                  params = params.first || Hash.new
                  send(#{method.to_sym.inspect}, path, params)
                end
              end
            end
          RUBY
        end
      end
    end
  end
end
