module Her
  module Model
    # This module interacts with Her::API to fetch HTTP data
    module HTTP
      # Link a model with a Her::API object
      def uses_api(api) # {{{
        @her_api = api
      end # }}}

      # Defines a custom collection path for the resource
      #
      # @example
      #  class User
      #    include Her::Model
      #    collection_path "users"
      #  end
      def collection_path(path=nil) # {{{
        return @her_collection_path unless path
        @her_collection_path = path
      end # }}}

      # Defines a custom item path for the resource
      #
      # @example
      #  class User
      #    include Her::Model
      #    item_path "user"
      #  end
      def item_path(path=nil) # {{{
        return @her_item_path unless path
        @her_item_path = path
      end # }}}

      # Main request wrapper around Her::API. Used to make custom request to the API.
      # @private
      def request(attrs={}, &block) # {{{
        yield @her_api.request(attrs)
      end # }}}

      # Make a GET request and return either a collection or a resource
      def get(path, attrs={}) # {{{
        path = "#{@her_collection_path}/#{path}" if path.is_a?(Symbol)
        get_raw(path, attrs) do |parsed_data|
          if parsed_data[:data].is_a?(Array)
            new_collection(parsed_data)
          else
            new(parsed_data[:data])
          end
        end
      end # }}}

      # Make a GET request and return the parsed JSON response (not mapped to objects)
      def get_raw(path, attrs={}, &block) # {{{
        path = "#{@her_collection_path}/#{path}" if path.is_a?(Symbol)
        request(attrs.merge(:_method => :get, :_path => path), &block)
      end # }}}

      # Make a GET request and return a collection of resources
      def get_collection(path, attrs={}) # {{{
        path = "#{@her_collection_path}/#{path}" if path.is_a?(Symbol)
        get_raw(path, attrs) do |parsed_data|
          new_collection(parsed_data)
        end
      end # }}}

      # Make a GET request and return a collection of resources
      def get_resource(path, attrs={}) # {{{
        path = "#{@her_collection_path}/#{path}" if path.is_a?(Symbol)
        get_raw(path, attrs) do |parsed_data|
          new(parsed_data[:data])
        end
      end # }}}

      # Make a POST request and return either a collection or a resource
      def post(path, attrs={}) # {{{
        path = "#{@her_collection_path}/#{path}" if path.is_a?(Symbol)
        post_raw(path, attrs) do |parsed_data|
          if parsed_data[:data].is_a?(Array)
            new_collection(parsed_data)
          else
            new(parsed_data[:data])
          end
        end
      end # }}}

      # Make a POST request and return the parsed JSON response (not mapped to objects)
      def post_raw(path, attrs={}, &block) # {{{
        path = "#{@her_collection_path}/#{path}" if path.is_a?(Symbol)
        request(attrs.merge(:_method => :post, :_path => path), &block)
      end # }}}

      # Make a POST request and return a collection of resources
      def post_collection(path, attrs={}) # {{{
        path = "#{@her_collection_path}/#{path}" if path.is_a?(Symbol)
        post_raw(path, attrs) do |parsed_data|
          new_collection(parsed_data)
        end
      end # }}}

      # Make a POST request and return a collection of resources
      def post_resource(path, attrs={}) # {{{
        path = "#{@her_collection_path}/#{path}" if path.is_a?(Symbol)
        post_raw(path, attrs) do |parsed_data|
          new(parsed_data[:data])
        end
      end # }}}

      # Make a PUT request and return either a collection or a resource
      def put(path, attrs={}) # {{{
        path = "#{@her_collection_path}/#{path}" if path.is_a?(Symbol)
        put_raw(path, attrs) do |parsed_data|
          if parsed_data[:data].is_a?(Array)
            new_collection(parsed_data)
          else
            new(parsed_data[:data])
          end
        end
      end # }}}

      # Make a PUT request and return the parsed JSON response (not mapped to objects)
      def put_raw(path, attrs={}, &block) # {{{
        path = "#{@her_collection_path}/#{path}" if path.is_a?(Symbol)
        request(attrs.merge(:_method => :put, :_path => path), &block)
      end # }}}

      # Make a PUT request and return a collection of resources
      def put_collection(path, attrs={}) # {{{
        path = "#{@her_collection_path}/#{path}" if path.is_a?(Symbol)
        put_raw(path, attrs) do |parsed_data|
          new_collection(parsed_data)
        end
      end # }}}

      # Make a PUT request and return a collection of resources
      def put_resource(path, attrs={}) # {{{
        path = "#{@her_collection_path}/#{path}" if path.is_a?(Symbol)
        put_raw(path, attrs) do |parsed_data|
          new(parsed_data[:data])
        end
      end # }}}

      # Make a PATCH request and return either a collection or a resource
      def patch(path, attrs={}) # {{{
        path = "#{@her_collection_path}/#{path}" if path.is_a?(Symbol)
        patch_raw(path, attrs) do |parsed_data|
          if parsed_data[:data].is_a?(Array)
            new_collection(parsed_data)
          else
            new(parsed_data[:data])
          end
        end
      end # }}}

      # Make a PATCH request and return the parsed JSON response (not mapped to objects)
      def patch_raw(path, attrs={}, &block) # {{{
        path = "#{@her_collection_path}/#{path}" if path.is_a?(Symbol)
        request(attrs.merge(:_method => :patch, :_path => path), &block)
      end # }}}

      # Make a PATCH request and return a collection of resources
      def patch_collection(path, attrs={}) # {{{
        path = "#{@her_collection_path}/#{path}" if path.is_a?(Symbol)
        patch_raw(path, attrs) do |parsed_data|
          new_collection(parsed_data)
        end
      end # }}}

      # Make a PATCH request and return a collection of resources
      def patch_resource(path, attrs={}) # {{{
        path = "#{@her_collection_path}/#{path}" if path.is_a?(Symbol)
        patch_raw(path, attrs) do |parsed_data|
          new(parsed_data[:data])
        end
      end # }}}

      # Make a DELETE request and return either a collection or a resource
      def delete(path, attrs={}) # {{{
        path = "#{@her_collection_path}/#{path}" if path.is_a?(Symbol)
        delete_raw(path, attrs) do |parsed_data|
          if parsed_data[:data].is_a?(Array)
            new_collection(parsed_data)
          else
            new(parsed_data[:data])
          end
        end
      end # }}}

      # Make a DELETE request and return the parsed JSON response (not mapped to objects)
      def delete_raw(path, attrs={}, &block) # {{{
        path = "#{@her_collection_path}/#{path}" if path.is_a?(Symbol)
        request(attrs.merge(:_method => :delete, :_path => path), &block)
      end # }}}

      # Make a DELETE request and return a collection of resources
      def delete_collection(path, attrs={}) # {{{
        path = "#{@her_collection_path}/#{path}" if path.is_a?(Symbol)
        delete_raw(path, attrs) do |parsed_data|
          new_collection(parsed_data)
        end
      end # }}}

      # Make a DELETE request and return a collection of resources
      def delete_resource(path, attrs={}) # {{{
        path = "#{@her_collection_path}/#{path}" if path.is_a?(Symbol)
        delete_raw(path, attrs) do |parsed_data|
          new(parsed_data[:data])
        end
      end # }}}
    end
  end
end
