module Her
  module Model
    # This module interacts with Her::API to fetch HTTP data
    module HTTP
      # Automatically inherit a superclass' api
      def her_api # {{{
        @her_api ||= begin
          superclass.her_api if superclass.respond_to?(:her_api)
        end
      end # }}}

      # Link a model with a Her::API object
      def uses_api(api) # {{{
        @her_api = api
      end # }}}

      # Main request wrapper around Her::API. Used to make custom request to the API.
      # @private
      def request(attrs={}) # {{{
        parsed_data = her_api.request(attrs)
        if block_given?
          yield parsed_data
        else
          parsed_data
        end
      end # }}}

      # Make a GET request and return either a collection or a resource
      #
      # @example
      #   class User
      #     include Her::Model
      #   end
      #
      #   @popular_users = User.get(:popular)
      #   # Fetched via GET "/users/popular"
      def get(path, attrs={}) # {{{
        path = "#{build_request_path(attrs)}/#{path}" if path.is_a?(Symbol)
        get_raw(path, attrs) do |parsed_data|
          if parsed_data[:data].is_a?(Array)
            new_collection(parsed_data)
          else
            new(parsed_data[:data].merge :_metadata => parsed_data[:data], :_errors => parsed_data[:errors])
          end
        end
      end # }}}

      # Make a GET request and return the parsed JSON response (not mapped to objects)
      def get_raw(path, attrs={}, &block) # {{{
        path = "#{build_request_path(attrs)}/#{path}" if path.is_a?(Symbol)
        request(attrs.merge(:_method => :get, :_path => path), &block)
      end # }}}

      # Make a GET request and return a collection of resources
      def get_collection(path, attrs={}) # {{{
        path = "#{build_request_path(attrs)}/#{path}" if path.is_a?(Symbol)
        get_raw(path, attrs) do |parsed_data|
          new_collection(parsed_data)
        end
      end # }}}

      # Make a GET request and return a collection of resources
      def get_resource(path, attrs={}) # {{{
        path = "#{build_request_path(attrs)}/#{path}" if path.is_a?(Symbol)
        get_raw(path, attrs) do |parsed_data|
          new(parsed_data[:data].merge :_metadata => parsed_data[:data], :_errors => parsed_data[:errors])
        end
      end # }}}

      # Make a POST request and return either a collection or a resource
      def post(path, attrs={}) # {{{
        path = "#{build_request_path(attrs)}/#{path}" if path.is_a?(Symbol)
        post_raw(path, attrs) do |parsed_data|
          if parsed_data[:data].is_a?(Array)
            new_collection(parsed_data)
          else
            new(parsed_data[:data].merge :_metadata => parsed_data[:data], :_errors => parsed_data[:errors])
          end
        end
      end # }}}

      # Make a POST request and return the parsed JSON response (not mapped to objects)
      def post_raw(path, attrs={}, &block) # {{{
        path = "#{build_request_path(attrs)}/#{path}" if path.is_a?(Symbol)
        request(attrs.merge(:_method => :post, :_path => path), &block)
      end # }}}

      # Make a POST request and return a collection of resources
      def post_collection(path, attrs={}) # {{{
        path = "#{build_request_path(attrs)}/#{path}" if path.is_a?(Symbol)
        post_raw(path, attrs) do |parsed_data|
          new_collection(parsed_data)
        end
      end # }}}

      # Make a POST request and return a collection of resources
      def post_resource(path, attrs={}) # {{{
        path = "#{build_request_path(attrs)}/#{path}" if path.is_a?(Symbol)
        post_raw(path, attrs) do |parsed_data|
          new(parsed_data[:data])
        end
      end # }}}

      # Make a PUT request and return either a collection or a resource
      def put(path, attrs={}) # {{{
        path = "#{build_request_path(attrs)}/#{path}" if path.is_a?(Symbol)
        put_raw(path, attrs) do |parsed_data|
          if parsed_data[:data].is_a?(Array)
            new_collection(parsed_data)
          else
            new(parsed_data[:data].merge :_metadata => parsed_data[:data], :_errors => parsed_data[:errors])
          end
        end
      end # }}}

      # Make a PUT request and return the parsed JSON response (not mapped to objects)
      def put_raw(path, attrs={}, &block) # {{{
        path = "#{build_request_path(attrs)}/#{path}" if path.is_a?(Symbol)
        request(attrs.merge(:_method => :put, :_path => path), &block)
      end # }}}

      # Make a PUT request and return a collection of resources
      def put_collection(path, attrs={}) # {{{
        path = "#{build_request_path(attrs)}/#{path}" if path.is_a?(Symbol)
        put_raw(path, attrs) do |parsed_data|
          new_collection(parsed_data)
        end
      end # }}}

      # Make a PUT request and return a collection of resources
      def put_resource(path, attrs={}) # {{{
        path = "#{build_request_path(attrs)}/#{path}" if path.is_a?(Symbol)
        put_raw(path, attrs) do |parsed_data|
          new(parsed_data[:data].merge :_metadata => parsed_data[:data], :_errors => parsed_data[:errors])
        end
      end # }}}

      # Make a PATCH request and return either a collection or a resource
      def patch(path, attrs={}) # {{{
        path = "#{build_request_path(attrs)}/#{path}" if path.is_a?(Symbol)
        patch_raw(path, attrs) do |parsed_data|
          if parsed_data[:data].is_a?(Array)
            new_collection(parsed_data)
          else
            new(parsed_data[:data].merge :_metadata => parsed_data[:data], :_errors => parsed_data[:errors])
          end
        end
      end # }}}

      # Make a PATCH request and return the parsed JSON response (not mapped to objects)
      def patch_raw(path, attrs={}, &block) # {{{
        path = "#{build_request_path(attrs)}/#{path}" if path.is_a?(Symbol)
        request(attrs.merge(:_method => :patch, :_path => path), &block)
      end # }}}

      # Make a PATCH request and return a collection of resources
      def patch_collection(path, attrs={}) # {{{
        path = "#{build_request_path(attrs)}/#{path}" if path.is_a?(Symbol)
        patch_raw(path, attrs) do |parsed_data|
          new_collection(parsed_data)
        end
      end # }}}

      # Make a PATCH request and return a collection of resources
      def patch_resource(path, attrs={}) # {{{
        path = "#{build_request_path(attrs)}/#{path}" if path.is_a?(Symbol)
        patch_raw(path, attrs) do |parsed_data|
          new(parsed_data[:data].merge :_metadata => parsed_data[:data], :_errors => parsed_data[:errors])
        end
      end # }}}

      # Make a DELETE request and return either a collection or a resource
      def delete(path, attrs={}) # {{{
        path = "#{build_request_path(attrs)}/#{path}" if path.is_a?(Symbol)
        delete_raw(path, attrs) do |parsed_data|
          if parsed_data[:data].is_a?(Array)
            new_collection(parsed_data)
          else
            new(parsed_data[:data].merge :_metadata => parsed_data[:data], :_errors => parsed_data[:errors])
          end
        end
      end # }}}

      # Make a DELETE request and return the parsed JSON response (not mapped to objects)
      def delete_raw(path, attrs={}, &block) # {{{
        path = "#{build_request_path(attrs)}/#{path}" if path.is_a?(Symbol)
        request(attrs.merge(:_method => :delete, :_path => path), &block)
      end # }}}

      # Make a DELETE request and return a collection of resources
      def delete_collection(path, attrs={}) # {{{
        path = "#{build_request_path(attrs)}/#{path}" if path.is_a?(Symbol)
        delete_raw(path, attrs) do |parsed_data|
          new_collection(parsed_data)
        end
      end # }}}

      # Make a DELETE request and return a collection of resources
      def delete_resource(path, attrs={}) # {{{
        path = "#{build_request_path(attrs)}/#{path}" if path.is_a?(Symbol)
        delete_raw(path, attrs) do |parsed_data|
          new(parsed_data[:data].merge :_metadata => parsed_data[:data], :_errors => parsed_data[:errors])
        end
      end # }}}

      # Define custom GET requests
      #
      # @example
      #   class User
      #     include Her::Model
      #     custom_get :popular
      #   end
      #
      #   User.popular
      #   # Fetched from GET "/users/popular"
      def custom_get(*paths) # {{{
        metaclass = (class << self; self; end)
        paths.each do |path|
          metaclass.send(:define_method, path.to_sym) do |*attrs|
            get(path, attrs.first || Hash.new)
          end
        end
      end # }}}

      # Define custom POST requests
      def custom_post(*paths) # {{{
        metaclass = (class << self; self; end)
        paths.each do |path|
          metaclass.send(:define_method, path.to_sym) do |*attrs|
            post(path, attrs.first || Hash.new)
          end
        end
      end # }}}

      # Define custom PUT requests
      def custom_put(*paths) # {{{
        metaclass = (class << self; self; end)
        paths.each do |path|
          metaclass.send(:define_method, path.to_sym) do |*attrs|
            put(path, attrs.first || Hash.new)
          end
        end
      end # }}}

      # Define custom PATCH requests
      def custom_patch(*paths) # {{{
        metaclass = (class << self; self; end)
        paths.each do |path|
          metaclass.send(:define_method, path.to_sym) do |*attrs|
            patch(path, attrs.first || Hash.new)
          end
        end
      end # }}}

      # Define custom DELETE requests
      def custom_delete(*paths) # {{{
        metaclass = (class << self; self; end)
        paths.each do |path|
          metaclass.send(:define_method, path.to_sym) do |*attrs|
            delete(path, attrs.first || Hash.new)
          end
        end
      end # }}}
    end
  end
end
