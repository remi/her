module Her
  module Model
    # This module interacts with Her::API to fetch HTTP data
    module HTTP
      extend ActiveSupport::Concern

      module ClassMethods
        # Automatically inherit a superclass' api
        def her_api
          @_her_api ||= begin
            if superclass.respond_to?(:her_api)
              superclass.her_api
            else
              Her::API.default_api
            end
          end
        end

        # Link a model with a Her::API object
        def uses_api(api)
          @_her_api = api
        end

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
        %w{GET POST PUT PATCH DELETE}.map(&:downcase).map(&:to_sym).each do |method|
          define_method method do |path, attrs={}|
            path = build_request_path_from_string_or_symbol(path, attrs)
            send("#{method}_raw".to_sym, path, attrs) do |parsed_data, response|
              if parsed_data[:data].is_a?(Array)
                new_collection(parsed_data)
              else
                new(parse(parsed_data[:data]).merge :_metadata => parsed_data[:metadata], :_errors => parsed_data[:errors])
              end
            end
          end

          define_method "#{method}_raw".to_sym do |path, attrs={}, &block|
            path = build_request_path_from_string_or_symbol(path, attrs)
            request(attrs.merge(:_method => method, :_path => path), &block)
          end

          define_method "#{method}_collection".to_sym do |path=nil, attrs={}|
            path = build_request_path_from_string_or_symbol(path, attrs)
            send("#{method}_raw".to_sym, build_request_path_from_string_or_symbol(path, attrs), attrs) do |parsed_data, response|
              new_collection(parsed_data)
            end
          end

          define_method "#{method}_resource".to_sym do |path, attrs={}|
            path = build_request_path_from_string_or_symbol(path, attrs)
            send("#{method}_raw".to_sym, path, attrs) do |parsed_data, response|
              new(parse(parsed_data[:data]).merge :_metadata => parsed_data[:metadata], :_errors => parsed_data[:errors])
            end
          end

          define_method "custom_#{method}".to_sym do |*paths|
            metaclass = (class << self; self; end)
            opts = paths.last.is_a?(Hash) ? paths.pop : Hash.new

            paths.each do |path|
              metaclass.send(:define_method, path.to_sym) do |*attrs|
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
