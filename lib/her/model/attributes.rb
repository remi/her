module Her
  module Model
    # This module handles all methods related to model attributes
    module Attributes
      extend ActiveSupport::Concern
      attr_reader :attributes

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
      end

      # Initialize a collection of resources
      #
      # @private
      def self.initialize_collection(klass, parsed_data={})
        collection_data = parsed_data[:data].map do |item_data|
          resource = klass.new(klass.parse(item_data))
          resource.run_callbacks :find
          resource
        end
        Her::Collection.new(collection_data, parsed_data[:metadata], parsed_data[:errors])
      end

      # Use setter methods of model for each key / value pair in params
      # Return key / value pairs for which no setter method was defined on the model
      #
      # @private
      def self.use_setter_methods(model, params)
        setter_method_names = model.class.setter_method_names
        params ||= {}
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
        if method.to_s =~ /[?=]$/ || attributes.include?(method)
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
      def respond_to?(method, include_private = false)
        method.to_s.end_with?('=') || method.to_s.end_with?('?') || @attributes.include?(method) || super
      end

      # @private
      def respond_to_missing?(method, include_private = false)
        method.to_s.end_with?('=') || method.to_s.end_with?('?') || @attributes.include?(method) || @attributes.include?(method) || super
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
        @attributes ||= {}
        # Use setter methods first, then translate attributes of associations
        # into association instances, then merge the parsed_data into @attributes.
        unset_attributes = Her::Model::Attributes.use_setter_methods(self, raw_data)
        parsed_attributes = self.class.parse_associations(unset_attributes)
        attributes.merge(parsed_attributes)
      end
      alias attributes= assign_attributes

      # Handles returning true for the accessible attributes
      #
      # @private
      def has_attribute?(attribute_name)
        attributes.include?(attribute_name)
      end

      # Handles returning data for a specific attribute
      #
      # @private
      def get_attribute(attribute_name)
        attributes[attribute_name]
      end

      # Return the value of the model `primary_key` attribute
      def id
        attributes[self.class.primary_key]
      end

      # Return `true` if the other object is also a Her::Model and has matching data
      #
      # @private
      def ==(other)
        other.is_a?(Her::Model) && attributes == other.attributes
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
        attributes.hash
      end

      module ClassMethods
        # Initialize a collection of resources with raw data from an HTTP request
        #
        # @param [Array] parsed_data
        # @private
        def new_collection(parsed_data)
          Her::Model::Attributes.initialize_collection(self, parsed_data)
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
          define_attribute_methods attributes

          attributes.each do |attribute|
            attribute = attribute.to_sym

            class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def #{attribute}
                @attributes.include?(:'#{attribute}') ? @attributes[:'#{attribute}'] : nil
              end

              def #{attribute}=(value)
                self.send(:"#{attribute}_will_change!") if @attributes[:'#{attribute}'] != value
                @attributes[:'#{attribute}'] = value
              end

              def #{attribute}?
                @attributes.include?(:'#{attribute}') && @attributes[:'#{attribute}'].present?
              end
            RUBY
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
          if @_her_store_response_errors
            remove_method @_her_store_response_errors
            remove_method :"#{@_her_store_response_errors}="
          end

          @_her_store_response_errors ||= begin
            superclass.store_response_errors if superclass.respond_to?(:store_response_errors)
          end

          return @_her_store_response_errors unless value
          @_her_store_response_errors = value

          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{@_her_store_response_errors}; @response_errors; end
            def #{@_her_store_response_errors}=(value); @response_errors = value; end
          RUBY
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
          if @_her_store_metadata
            remove_method @_her_store_metadata
            remove_method :"#{@_her_store_metadata}="
          end

          @_her_store_metadata ||= begin
            superclass.store_metadata if superclass.respond_to?(:store_metadata)
          end

          return @_her_store_metadata unless value
          @_her_store_metadata = value

          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{@_her_store_metadata}; @metadata; end
            def #{@_her_store_metadata}=(value); @metadata = value; end
          RUBY
        end

        # @private
        def setter_method_names
          @_her_setter_method_names ||= instance_methods.inject(Set.new) do |memo, method_name|
            memo << method_name.to_s if method_name.to_s.end_with?('=')
            memo
          end
        end
      end
    end
  end
end
