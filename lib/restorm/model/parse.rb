module Restorm
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
        self.class.to_params(attributes, changes)
      end

      module ClassMethods
        # Parse data before assigning it to a resource, based on `parse_root_in_json`.
        #
        # @param [Hash] data
        # @private
        def parse(data)
          if parse_root_in_json? && root_element_included?(data)
            if json_api_format?
              data.fetch(parsed_root_element).first
            else
              data.fetch(parsed_root_element) { data }
            end
          else
            data
          end
        end

        # @private
        def to_params(attributes, changes = {})
          filtered_attributes = attributes.each_with_object({}) do |(key, value), memo|
            case value
            when Restorm::Model
            when ActiveModel::Serialization
              value = value.serializable_hash.symbolize_keys
            end

            memo[key.to_sym] = value
          end

          filtered_attributes.merge!(embeded_params(attributes))

          if restorm_api.options[:send_only_modified_attributes]
            filtered_attributes.slice! *changes.keys.map(&:to_sym)
          end

          if include_root_in_json?
            if json_api_format?
              { included_root_element => [filtered_attributes] }
            else
              { included_root_element => filtered_attributes }
            end
          else
            filtered_attributes
          end
        end

        # @private
        def embeded_params(attributes)
          associations.values.flatten.each_with_object({}) do |definition, hash|
            value = case association = attributes[definition[:name]]
                    when Restorm::Collection, Array
                      association.map { |a| a.to_params }.reject(&:empty?)
                    when Restorm::Model
                      association.to_params
                    end
            hash[definition[:data_key]] = value if value.present?
          end
        end

        # Return or change the value of `include_root_in_json`
        #
        # @example
        #   class User
        #     include Restorm::Model
        #     include_root_in_json true
        #   end
        def include_root_in_json(value, options = {})
          @_restorm_include_root_in_json = value
          @_restorm_include_root_in_json_format = options[:format]
        end

        # Return or change the value of `parse_root_in_json`
        #
        # @example
        #   class User
        #     include Restorm::Model
        #     parse_root_in_json true
        #   end
        #
        #   class User
        #     include Restorm::Model
        #     parse_root_in_json true, format: :active_model_serializers
        #   end
        #
        #   class User
        #     include Restorm::Model
        #     parse_root_in_json true, format: :json_api
        #   end
        def parse_root_in_json(value, options = {})
          @_restorm_parse_root_in_json = value
          @_restorm_parse_root_in_json_format = options[:format]
        end

        # Return or change the value of `request_new_object_on_build`
        #
        # @example
        #   class User
        #     include Restorm::Model
        #     request_new_object_on_build true
        #   end
        def request_new_object_on_build(value = nil)
          @_restorm_request_new_object_on_build = value
        end

        # Return or change the value of `root_element`. Always defaults to the base name of the class.
        #
        # @example
        #   class User
        #     include Restorm::Model
        #     parse_root_in_json true
        #     root_element :huh
        #   end
        #
        #   user = User.find(1) # { :huh => { :id => 1, :name => "Tobias" } }
        #   user.name # => "Tobias"
        def root_element(value = nil)
          if value.nil?
            @_retorm_root_element ||= if json_api_format?
                                     name.split("::").last.pluralize.underscore.to_sym
                                   else
                                     name.split("::").last.underscore.to_sym
                                   end
          else
            @_restorm_root_element = value.to_sym
          end
        end

        # @private
        def root_element_included?(data)
          element = data[parsed_root_element]
          element.is_a?(Hash) || element.is_a?(Array)
        end

        # @private
        def included_root_element
          include_root_in_json? == true ? root_element : include_root_in_json?
        end

        # Extract an array from the request data
        #
        # @example
        #   # with parse_root_in_json true, :format => :active_model_serializers
        #   class User
        #     include Restorm::Model
        #     parse_root_in_json true, :format => :active_model_serializers
        #   end
        #
        #   users = User.all # { :users => [ { :id => 1, :name => "Tobias" } ] }
        #   users.first.name # => "Tobias"
        #
        #   # without parse_root_in_json
        #   class User
        #     include Restorm::Model
        #   end
        #
        #   users = User.all # [ { :id => 1, :name => "Tobias" } ]
        #   users.first.name # => "Tobias"
        #
        # @private
        def extract_array(request_data)
          if request_data[:data].is_a?(Hash) && (active_model_serializers_format? || json_api_format?)
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
          @_restorm_parse_root_in_json_format == :active_model_serializers || (superclass.respond_to?(:active_model_serializers_format?) && superclass.active_model_serializers_format?)
        end

        # @private
        def json_api_format?
          @_restorm_parse_root_in_json_format == :json_api || (superclass.respond_to?(:json_api_format?) && superclass.json_api_format?)
        end

        # @private
        def request_new_object_on_build?
          return @_restorm_request_new_object_on_build unless @_restorm_request_new_object_on_build.nil?
          superclass.respond_to?(:request_new_object_on_build?) && superclass.request_new_object_on_build?
        end

        # @private
        def include_root_in_json?
          return @_restorm_include_root_in_json unless @_restorm_include_root_in_json.nil?
          superclass.respond_to?(:include_root_in_json?) && superclass.include_root_in_json?
        end

        # @private
        def parse_root_in_json?
          return @_restorm_parse_root_in_json unless @_restorm_parse_root_in_json.nil?
          superclass.respond_to?(:parse_root_in_json?) && superclass.parse_root_in_json?
        end
      end
    end
  end
end
