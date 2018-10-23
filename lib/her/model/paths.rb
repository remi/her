module Her
  module Model
    module Paths
      extend ActiveSupport::Concern
      # Return a path based on the collection path and a resource data
      #
      # @example
      #   class User
      #     include Her::Model
      #     collection_path "/utilisateurs"
      #   end
      #
      #   User.find(1) # Fetched via GET /utilisateurs/1
      #
      # @param [Hash] params An optional set of additional parameters for
      #   path construction. These will not override attributes of the resource.
      def request_path(params = {})
        self.class.build_request_path(params.merge(attributes))
      end

      module ClassMethods
        # Define the primary key field that will be used to find and save records
        #
        # @example
        #  class User
        #    include Her::Model
        #    primary_key 'UserId'
        #  end
        #
        # @param [Symbol] value
        def primary_key(value = nil)
          @_her_primary_key ||= begin
            superclass.primary_key if superclass.respond_to?(:primary_key)
          end

          return @_her_primary_key unless value
          @_her_primary_key = value.to_sym
        end

        # Defines a custom collection path for the resource
        #
        # @example
        #  class User
        #    include Her::Model
        #    collection_path "/users"
        #  end
        def collection_path(path = nil)
          if path.nil?
            @_her_collection_path ||= root_element.to_s.pluralize
          else
            @_her_collection_path = path
            @_her_resource_path = "#{path}/:id"
          end
        end

        # Defines a custom resource path for the resource
        #
        # @example
        #  class User
        #    include Her::Model
        #    resource_path "/users/:id"
        #  end
        #
        # Note that, if used in combination with resource_path, you may specify
        # either the real primary key or the string ':id'. For example:
        #
        # @example
        #  class User
        #    include Her::Model
        #    primary_key 'user_id'
        #
        #    # This works because we'll have a user_id attribute
        #    resource_path '/users/:user_id'
        #
        #    # This works because we replace :id with :user_id
        #    resource_path '/users/:id'
        #  end
        #
        def resource_path(path = nil)
          if path.nil?
            @_her_resource_path ||= "#{root_element.to_s.pluralize}/:id"
          else
            @_her_resource_path = path
          end
        end

        # Return a custom path based on the resource or collection
        # path and variable parameters.
        #
        # If :collection option is true then a collection path is
        # forced, regardless of whether the primary key is in the
        # parameters.
        #
        # If :remove_used option is true then parameters used in that
        # path will be removed from the hash.
        #
        # @private
        def build_request_path(parameters = {}, options = {})
          path =
            if options[:collection]
              collection_path.dup
            else
              pkey = parameters[primary_key.to_s] || parameters[primary_key.to_sym]

              if pkey && !pkey.is_a?(Array)
                resource_path.dup
              else
                collection_path.dup
              end
            end

          # Replace :id with our actual primary key
          path.gsub!(/(\A|\/):id(\z|\/)/, "\\1:#{primary_key}\\2")

          used = []
          missing = []

          result = path.gsub(/:([\w_]+)/) do
            # Look for "key" or "_key", otherwise add to the missing
            # list and raise below.
            replacement = nil
            [$1, "_#{$1}"].each do |str_key|
              [str_key, str_key.to_sym].each do |key|
                value = parameters[key]
                next unless value
                used << key if options[:remove_used]
                replacement = value
                break 2
              end
            end

            unless replacement
              replacement = $1
              missing << $1.to_sym
            end

            Faraday::Utils.escape replacement
          end

          if missing.empty?
            parameters.except! *used
            result
          else
            joined = missing.map { |m| ":_#{m}" }.join(", ")
            raise Her::Errors::PathError.new("Missing #{joined} parameters to build the request path. Path is `#{path}`. Parameters are `#{parameters.symbolize_keys.inspect}`.", missing)
          end
        end

        # @private
        def build_request_path_from_string_or_symbol(path, params = {})
          path.is_a?(Symbol) ? "#{build_request_path(params)}/#{path}" : path
        end
      end
    end
  end
end
