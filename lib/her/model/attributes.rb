module Her
  module Model
    # This module handles all methods related to model attributes
    module Attributes
      extend ActiveSupport::Concern

      attr_accessor :attributes, :metadata, :response_errors
      alias :data :attributes
      alias :data= :attributes=

      # Initialize a new object with data
      def initialize(attributes={})
        attributes ||= {}
        @metadata = attributes.delete(:_metadata) || {}
        @response_errors = attributes.delete(:_errors) || {}
        @destroyed = attributes.delete(:_destroyed) || false

        assign_attributes(attributes)
      end

      # Initialize a collection of resources
      # @private
      def self.initialize_collection(klass, parsed_data={})
        collection_data = parsed_data[:data].map do |item_data|
          parsed = klass.parse(item_data)
          subclass = klass.class_for_data(parsed)
          resource = subclass.new(parsed)
          resource.run_callbacks :find
          resource
        end
        Her::Collection.new(collection_data, parsed_data[:metadata], parsed_data[:errors])
      end

      # Use setter methods of model for each key / value pair in params
      # Return key / value pairs for which no setter method was defined on the model
      # @private
      def self.use_setter_methods(model, params)
        setter_method_names = model.class.setter_method_names
        params ||= {}
        params.inject({}) do |memo, (key, value)|
          setter_method = key.to_s + '='
          if setter_method_names.include?(setter_method)
            model.send(setter_method, value)
          else
            if key.is_a?(String)
              key = key.to_sym
            end
            memo[key] = value
          end
          memo
        end
      end

      # Handles missing methods
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

      # Assign new attributes
      # @private
      def assign_attributes(raw_data)
        @attributes ||= {}
        # Use setter methods first, then translate attributes of associations
        # into association instances, then merge the parsed_data into @attributes.
        unset_attributes = Her::Model::Attributes.use_setter_methods(self, raw_data)
        parsed_attributes = self.class.parse_associations(unset_attributes)
        attributes.update(parsed_attributes)
      end
      alias :update_attributes :assign_attributes
      alias :assign_data :assign_attributes

      # Handles returning true for the accessible attributes
      # @private
      def has_attribute?(attribute_name)
        attributes.include?(attribute_name)
      end
      alias :has_data? :has_attribute?

      # Handles returning data for a specific attribute
      # @private
      def get_attribute(attribute_name)
        attributes[attribute_name]
      end
      alias :get_data :get_attribute

      # Override the method to prevent from returning the object ID
      # @private
      def id
        attributes[self.class.primary_key] || super
      end

      # Return `true` if the other object is also a Her::Model and has matching data
      # @private
      def ==(other)
        other.is_a?(Her::Model) && attributes == other.attributes
      end

      # Delegate to the == method
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
        def new_collection(parsed_data)
          Her::Model::Attributes.initialize_collection(self, parsed_data)
        end

        # Define the attributes that will be used to track dirty attributes and validations
        #
        # @param [Array] attributes
        def attributes(*attributes)
          define_attribute_methods attributes

          attributes.each do |attribute|
            attribute = attribute.to_sym

            define_method "#{attribute}".to_sym do
              @attributes.include?(attribute) ? @attributes[attribute] : nil
            end

            define_method "#{attribute}=".to_sym do |value|
              self.send("#{attribute}_will_change!".to_sym) if @attributes[attribute] != value
              @attributes[attribute] = value
            end

            define_method "#{attribute}?".to_sym do
              @attributes.include?(attribute) && @attributes[attribute].present?
            end
          end
        end
        
        # Returns the class that should be instantiated to represent the given data
        #
        # @param [Array] parsed_data
        def class_for_data(parsed_data)
          self
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
