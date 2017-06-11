module Her
  module Model
    # This module handles all methods related to model attributes
    module Attributes
      extend ActiveSupport::Concern

      # Initialize a new object with data
      #
      # @param [Hash] attributes The attributes to initialize the object with
      # @option attributes [Hash,Array] :_metadata
      # @option attributes [Hash,Array] :_errors
      # @option attributes [Boolean] :_destroyed
      #
      # @example
      #   class User
      #     include Her::Model
      #   end
      #
      #  User.new(name: "Tobias") # => #<User name="Tobias">
      def initialize(attributes={})
        attributes ||= {}
        @metadata = attributes.delete(:_metadata) || {}
        @response_errors = attributes.delete(:_errors) || {}
        @destroyed = attributes.delete(:_destroyed) || false

        attributes = self.class.default_scope.apply_to(attributes)
        assign_attributes(attributes)

        yield self if block_given?
        run_callbacks :initialize
      end

      # Initialize a collection of resources
      #
      # @private
      def self.initialize_collection(klass, parsed_data={})
        collection_data = klass.extract_array(parsed_data).map do |item_data|
          if item_data.kind_of?(klass)
            resource = item_data
          else
            resource = klass.new(klass.parse(item_data))
            resource.run_callbacks :find
          end
          resource
        end
        Her::Collection.new(collection_data, parsed_data[:metadata], parsed_data[:errors])
      end

      # Use setter methods of model for each key / value pair in params
      # Return key / value pairs for which no setter method was defined on the model
      #
      # @private
      def self.use_setter_methods(model, params)
        params ||= {}

        reserved_keys = [:id, model.class.primary_key] + model.class.association_keys
        model.class.attributes *params.keys.reject { |k| reserved_keys.include?(k) || reserved_keys.map(&:to_s).include?(k) }

        setter_method_names = model.class.setter_method_names
        params.inject({}) do |memo, (key, value)|
          setter_method = key.to_s + '='
          if setter_method_names.include?(setter_method)
            model.send(setter_method, value)
          else
            key = key.to_sym if key.is_a?(String)
            memo[key] = value
          end
          memo
        end
      end

      # Handles missing methods
      #
      # @private
      def method_missing(method, *args, &blk)
        if method.to_s =~ /[?=]$/ || @attributes.include?(method)
          # Extract the attribute
          attribute = method.to_s.sub(/[?=]$/, '')

          # Create a new `attribute` methods set
          self.class.attributes(*attribute)

          # Resend the method!
          send(method, *args, &blk)
        else
          super
        end
      end

      # @private
      def respond_to_missing?(method, include_private = false)
        method.to_s.end_with?('=') || method.to_s.end_with?('?') || @attributes.include?(method) || super
      end

      # Assign new attributes to a resource
      #
      # @example
      #   class User
      #     include Her::Model
      #   end
      #
      #   user = User.find(1) # => #<User id=1 name="Tobias">
      #   user.assign_attributes(name: "Lindsay")
      #   user.changes # => { :name => ["Tobias", "Lindsay"] }
      def assign_attributes(new_attributes)
        @attributes ||= attributes
        # Use setter methods first
        unset_attributes = Her::Model::Attributes.use_setter_methods(self, new_attributes)

        # Then translate attributes of associations into association instances
        parsed_attributes = self.class.parse_associations(unset_attributes)

        # Then merge the parsed_data into @attributes.
        @attributes.merge!(parsed_attributes)
      end
      alias attributes= assign_attributes

      def attributes
        @attributes ||= HashWithIndifferentAccess.new
      end

      # Handles returning true for the accessible attributes
      #
      # @private
      def has_attribute?(attribute_name)
        @attributes.include?(attribute_name)
      end

      # Handles returning data for a specific attribute
      #
      # @private
      def get_attribute(attribute_name)
        @attributes[attribute_name]
      end
      alias attribute get_attribute

      # Return the value of the model `primary_key` attribute
      def id
        @attributes[self.class.primary_key]
      end

      # Return `true` if the other object is also a Her::Model and has matching data
      #
      # @private
      def ==(other)
        other.is_a?(Her::Model) && @attributes == other.attributes
      end

      # Delegate to the == method
      #
      # @private
      def eql?(other)
        self == other
      end

      # Delegate to @attributes, allowing models to act correctly in code like:
      #     [ Model.find(1), Model.find(1) ].uniq # => [ Model.find(1) ]
      # @private
      def hash
        @attributes.hash
      end

      # Assign attribute value (ActiveModel convention method).
      #
      # @private
      def attribute=(attribute, value)
        @attributes[attribute] = nil unless @attributes.include?(attribute)
        self.send(:"#{attribute}_will_change!") if @attributes[attribute] != value
        @attributes[attribute] = value
      end

      # Check attribute value to be present (ActiveModel convention method).
      #
      # @private
      def attribute?(attribute)
        @attributes.include?(attribute) && @attributes[attribute].present?
      end

      module ClassMethods
        # Initialize a collection of resources with raw data from an HTTP request
        #
        # @param [Array] parsed_data
        # @private
        def new_collection(parsed_data)
          Her::Model::Attributes.initialize_collection(self, parsed_data)
        end

        # Initialize a new object with the "raw" parsed_data from the parsing middleware
        #
        # @private
        def new_from_parsed_data(parsed_data)
          parsed_data = parsed_data.with_indifferent_access
          new(parse(parsed_data[:data]).merge :_metadata => parsed_data[:metadata], :_errors => parsed_data[:errors])
        end

        # Define attribute method matchers to automatically define them using ActiveModel's define_attribute_methods.
        #
        # @private
        def define_attribute_method_matchers
          attribute_method_suffix '='
          attribute_method_suffix '?'
        end

        # Create a mutex for dynamically generated attribute methods or use one defined by ActiveModel.
        #
        # @private
        def attribute_methods_mutex
          @attribute_methods_mutex ||= if generated_attribute_methods.respond_to? :mu_synchronize
                                         generated_attribute_methods
                                       else
                                         Mutex.new
                                       end
        end

        # Define the attributes that will be used to track dirty attributes and validations
        #
        # @param [Array] attributes
        # @example
        #   class User
        #     include Her::Model
        #     attributes :name, :email
        #   end
        def attributes(*attributes)
          attribute_methods_mutex.synchronize do
            define_attribute_methods attributes
          end
        end

        # Define the accessor in which the API response errors (obtained from the parsing middleware) will be stored
        #
        # @param [Symbol] store_response_errors
        #
        # @example
        #   class User
        #     include Her::Model
        #     store_response_errors :server_errors
        #   end
        def store_response_errors(value = nil)
          store_her_data(:response_errors, value)
        end

        # Define the accessor in which the API response metadata (obtained from the parsing middleware) will be stored
        #
        # @param [Symbol] store_metadata
        #
        # @example
        #   class User
        #     include Her::Model
        #     store_metadata :server_data
        #   end
        def store_metadata(value = nil)
          store_her_data(:metadata, value)
        end

        # @private
        def setter_method_names
          @_her_setter_method_names ||= instance_methods.inject(Set.new) do |memo, method_name|
            memo << method_name.to_s if method_name.to_s.end_with?('=')
            memo
          end
        end

        private
        # @private
        def store_her_data(name, value)
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            if @_her_store_#{name} && value.present?
              remove_method @_her_store_#{name}.to_sym
              remove_method @_her_store_#{name}.to_s + '='
            end

            @_her_store_#{name} ||= begin
              superclass.store_#{name} if superclass.respond_to?(:store_#{name})
            end

            return @_her_store_#{name} unless value
            @_her_store_#{name} = value

            define_method(value) { @#{name} }
            define_method(value.to_s+'=') { |value| @#{name} = value }
          RUBY
        end
      end
    end
  end
end
