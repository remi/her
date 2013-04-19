module Her
  module Model
    # This module interacts with Her::API to fetch HTTP data
    module HTTP
      extend ActiveSupport::Concern

      module ClassMethods
        # Change which API the model will use to make its HTTP requests
        def use_api(value = nil)
          @_her_use_api ||= begin
            superclass.use_api if superclass.respond_to?(:use_api)
          end

          return @_her_use_api unless value
          @_her_use_api = value
        end
        alias :her_api :use_api
        alias :uses_api :use_api

        # Main request wrapper around Her::API. Used to make custom request to the API.
        # @private
        def request(attrs={})
          request = her_api.request(attrs)

          if block_given?
            yield request[:parsed_data], request[:response]
          else
            { :parsed_data => request[:parsed_data], :response => request[:response] }
          end
        end

        # For each HTTP method, define these methods:
        #
        # - <method>(path, attrs)
        # - <method>_raw(path, attrs, &block)
        # - <method>_collection(path, attrs, &block)
        # - <method>_resource(path, attrs, &block)
        # - custom_<method>(path, attrs)
        [:get, :post, :put, :patch, :delete].each do |method|
          define_method method do |path, attrs={}|
            path = build_request_path_from_string_or_symbol(path, attrs)
            send(:"#{method}_raw", path, attrs) do |parsed_data, response|
              if parsed_data[:data].is_a?(Array)
                new_collection(parsed_data)
              else
                new(parse(parsed_data[:data]).merge :_metadata => parsed_data[:metadata], :_errors => parsed_data[:errors])
              end
            end
          end

          define_method :"#{method}_raw" do |path, attrs={}, &block|
            path = build_request_path_from_string_or_symbol(path, attrs)
            request(attrs.merge(:_method => method, :_path => path), &block)
          end

          define_method :"#{method}_collection" do |path=nil, attrs={}|
            path = build_request_path_from_string_or_symbol(path, attrs)
            send(:"#{method}_raw", build_request_path_from_string_or_symbol(path, attrs), attrs) do |parsed_data, response|
              new_collection(parsed_data)
            end
          end

          define_method :"#{method}_resource" do |path, attrs={}|
            path = build_request_path_from_string_or_symbol(path, attrs)
            send(:"#{method}_raw", path, attrs) do |parsed_data, response|
              new(parse(parsed_data[:data]).merge :_metadata => parsed_data[:metadata], :_errors => parsed_data[:errors])
            end
          end

          define_method :"custom_#{method}" do |*paths|
            metaclass = (class << self; self; end)
            opts = paths.last.is_a?(Hash) ? paths.pop : Hash.new

            paths.each do |path|
              metaclass.send(:define_method, path) do |*attrs|
                attrs = attrs.first || Hash.new
                send(method, path, attrs)
              end
            end
          end
        end
      end
    end
  end
end
