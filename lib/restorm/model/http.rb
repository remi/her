module Restorm
  module Model
    # This module interacts with Restorm::API to fetch HTTP data
    module HTTP
      extend ActiveSupport::Concern
      METHODS = [:get, :post, :put, :patch, :delete, :options]

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
      #     include Restorm::Model
      #     custom_get :active
      #   end
      #
      #   User.get(:popular) # GET "/users/popular"
      #   User.active # GET "/users/active"
      module ClassMethods
        # Change which API the model will use to make its HTTP requests
        #
        # @example
        #   secondary_api = Restorm::API.new :url => "https://api.example" do |connection|
        #     connection.use Faraday::Request::UrlEncoded
        #     connection.use Restorm::Middleware::DefaultParseJSON
        #   end
        #
        #   class User
        #     include Restorm::Model
        #     use_api secondary_api
        #   end
        def use_api(value = nil)
          @_restorm_use_api ||= begin
            superclass.use_api if superclass.respond_to?(:use_api)
          end

          unless value
            return (@_restorm_use_api.respond_to? :call) ? @_restorm_use_api.call : @_restorm_use_api
          end

          @_restorm_use_api = value
        end

        alias restorm_api use_api
        alias uses_api use_api

        # Main request wrapper around Restorm::API. Used to make custom request to the API.
        #
        # @private
        def request(params = {})
          request = restorm_api.request(params)

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
                  new_from_parsed_data(parsed_data)
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
                new_from_parsed_data(parsed_data)
              end
            end

            def custom_#{method}(*paths)
              metaclass = (class << self; self; end)

              # TODO: Remove this check after January 2020
              if paths.last.is_a?(Hash)
                warn("[DEPRECATION] options for custom request methods are deprecated and will be removed on or after January 2020.")
                paths.pop
              end

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
