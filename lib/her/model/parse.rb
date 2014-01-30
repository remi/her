module Her
  module Model
    # This module handles resource data parsing at the model level (after the parsing middleware)
    module Parse
      extend ActiveSupport::Concern

      # Convert into a hash of request parameters, based on `include_root_in_json`.
      #
      # @example
      #   @user.to_params
      #   # => { :id => 1, :name => 'John Smith' }
      def to_params
        self.class.to_params(self.attributes, self.changes)
      end

      module ClassMethods
        # Parse data before assigning it to a resource, based on `parse_root_in_json`.
        #
        # @param [Hash] data
        # @private
        def parse(data)
          parse_root_in_json? ? data.fetch(parsed_root_element) { data } : data
        end

        # @private
        def to_params(attributes, changes={})
          filtered_attributes = jsonapi_format_include? ? [attributes.dup.symbolize_keys] : attributes.dup.symbolize_keys
          if her_api.options[:send_only_modified_attributes]
            filtered_attributes = changes.symbolize_keys.keys.inject({}) do |hash, attribute|
              hash[attribute] = filtered_attributes[attribute]
              hash
            end
          end
          include_root_in_json? ? { included_root_element => filtered_attributes } : filtered_attributes
        end

        # Return or change the value of `include_root_in_json`
        #
        # @example
        #   class User
        #     include Her::Model
        #     include_root_in_json true, format: jsonapi
        #   end
        def include_root_in_json(value = nil, options = {})
          @_her_include_root_in_json ||= begin
            superclass.include_root_in_json if superclass.respond_to?(:include_root_in_json)
          end

          return @_her_include_root_in_json unless value
          @_her_include_root_in_json = value
          @_her_jsonapi_format_include = options[:format] == :jsonapi
        end

        def include_root_in_json?
          @_her_include_root_in_json || (superclass.respond_to?(:include_root_in_json?) && superclass.include_root_in_json?)
        end

        def jsonapi_format_include?
          @_her_jsonapi_format_include
        end

        # Return or change the value of `parse_root_in`
        #
        # @example
        #   class User
        #     include Her::Model
        #     parse_root_in_json true
        #   end
        def parse_root_in_json(value = nil, options = {})
          @_her_parse_root_in_json ||= begin
            superclass.parse_root_in_json if superclass.respond_to?(:parse_root_in_json)
          end

          return @_her_parse_root_in_json unless value
          @_her_parse_root_in_json = value
          @_her_jsonapi_format = options[:format] == :jsonapi]
        end

        def parse_root_in_json?
          @_her_parse_root_in_json || (superclass.respond_to?(:parse_root_in_json?) && superclass.parse_root_in_json?)
        end

        def jsonapi_format?
          @_her_jsonapi_format
        end

        # Return or change the value of `request_new_object_on_build`
        #
        # @example
        #   class User
        #     include Her::Model
        #     request_new_object_on_build true
        #   end
        def request_new_object_on_build(value = nil)
          @_her_request_new_object_on_build = value
        end

        def request_new_object_on_build?
          @_her_request_new_object_on_build || (superclass.respond_to?(:request_new_object_on_build?) && superclass.request_new_object_on_build?)
        end

        # Return or change the value of `root_element`. Always defaults to the base name of the class.
        #
        # @example
        #   class User
        #     include Her::Model
        #     parse_root_in_json true
        #     root_element :huh
        #   end
        #
        #   user = User.find(1) # { :huh => { :id => 1, :name => "Tobias" } }
        #   user.name # => "Tobias"
        def root_element(value = nil)
          if value.nil?
            if jsonapi_format?
              @_her_root_element ||= self.name.split("::").last.pluralize.underscore.to_sym
            else
              @_her_root_element ||= self.name.split("::").last.underscore.to_sym
            end
          else
            @_her_root_element = value.to_sym
          end
        end

        # Same as root_element, but separated option for include
        def root_element_include
          if jsonapi_format_include?
            @_her_root_element_include ||= self.name.split("::").last.pluralize.underscore.to_sym
          else
            @_her_root_element_include ||= self.name.split("::").last.underscore.to_sym
          end
        end

        # @private
        def included_root_element
          include_root_in_json == true ? root_element_include : include_root_in_json
        end

        # Extract an array from the request data
        #
        # @example
        #   # with parse_root_in_json true, :format => :active_model_serializers
        #   class User
        #     include Her::Model
        #     parse_root_in_json true, :format => :active_model_serializers
        #   end
        #
        #   users = User.all # { :users => [ { :id => 1, :name => "Tobias" } ] }
        #   users.first.name # => "Tobias"
        #
        #   # without parse_root_in_json
        #   class User
        #     include Her::Model
        #   end
        #
        #   users = User.all # [ { :id => 1, :name => "Tobias" } ]
        #   users.first.name # => "Tobias"
        def extract_array(request_data)
          if active_model_serializers_format?
            request_data[:data][pluralized_parsed_root_element]
          else
            request_data[:data]
          end
        end

        # @private
        def pluralized_parsed_root_element
          parsed_root_element.to_s.pluralize.to_sym
        end

        # @private
        def parsed_root_element
          parse_root_in_json? == true ? root_element : parse_root_in_json?
        end

        # @private
        def active_model_serializers_format?
          @_her_parse_root_in_json_format == :active_model_serializers || (superclass.respond_to?(:active_model_serializers_format?) && superclass.active_model_serializers_format?)
        end
      end
    end
  end
end
