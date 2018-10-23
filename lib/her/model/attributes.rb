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
      #   User.new(name: "Tobias")
      #   # => #<User name="Tobias">
      #
      #   User.new do |u|
      #     u.name = "Tobias"
      #   end
      #   # => #<User name="Tobias">
      def initialize(attributes = {})
        attributes ||= {}
        @metadata = attributes.delete(:_metadata) || {}
        @response_errors = attributes.delete(:_errors) || {}
        @destroyed = attributes.delete(:_destroyed) || false

        attributes = self.class.default_scope.apply_to(attributes)
        assign_attributes(attributes)
        yield self if block_given?
        run_callbacks :initialize
      end

      # Handles missing methods
      #
      # @private
      def method_missing(method, *args, &blk)
        if method.to_s =~ /[?=]$/ || @_her_attributes.include?(method)
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
        method.to_s =~ /[?=]$/ || @_her_attributes.include?(method) || super
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
        @_her_attributes ||= attributes
        # Use setter methods first
        unset_attributes = self.class.use_setter_methods(self, new_attributes)

        # Then translate attributes of associations into association instances
        associations = self.class.parse_associations(unset_attributes)

        # Then merge the associations into @_her_attributes.
        @_her_attributes.merge!(associations)
      end
      alias attributes= assign_attributes

      def attributes
        # The natural choice of instance variable naming here would be
        # `@attributes`. Unfortunately that causes a naming clash when
        # used with `ActiveModel` version >= 5.2.0.
        # As of v5.2.0 `ActiveModel` checks to see if `ActiveRecord`
        # attributes exist, and assumes that if the instance variable
        # `@attributes` exists on the instance, it is because they are
        # `ActiveRecord` attributes.
        @_her_attributes ||= HashWithIndifferentAccess.new
      end

      # Handles returning true for the accessible attributes
      #
      # @private
      def has_attribute?(attribute_name)
        @_her_attributes.include?(attribute_name)
      end

      # Handles returning data for a specific attribute
      #
      # @private
      def get_attribute(attribute_name)
        @_her_attributes[attribute_name]
      end
      alias attribute get_attribute

      # Return the value of the model `primary_key` attribute
      def id
        @_her_attributes[self.class.primary_key]
      end

      # Return `true` if the other object is also a Her::Model and has matching
      # data
      #
      # @private
      def ==(other)
        other.is_a?(Her::Model) && @_her_attributes == other.attributes
      end

      # Delegate to the == method
      #
      # @private
      def eql?(other)
        self == other
      end

      # Delegate to @_her_attributes, allowing models to act correctly in code like:
      #     [ Model.find(1), Model.find(1) ].uniq # => [ Model.find(1) ]
      # @private
      def hash
        @_her_attributes.hash
      end

      # Assign attribute value (ActiveModel convention method).
      #
      # @private
      def attribute=(attribute, value)
        @_her_attributes[attribute] = nil unless @_her_attributes.include?(attribute)
        send("#{attribute}_will_change!") unless value == @_her_attributes[attribute]
        @_her_attributes[attribute] = value
      end

      # Check attribute value to be present (ActiveModel convention method).
      #
      # @private
      def attribute?(attribute)
        @_her_attributes.include?(attribute) && @_her_attributes[attribute].present?
      end

      module ClassMethods
        # Initialize a single resource
        #
        # @private
        def instantiate_record(klass, parsed_data)
          if (record = parsed_data[:data]) && record.is_a?(klass)
            record
          else
            attributes = klass.parse(record).merge(_metadata: parsed_data[:metadata],
                                                   _errors: parsed_data[:errors])
            klass.new(attributes).tap do |record_instance|
              record_instance.send :clear_changes_information
              record_instance.run_callbacks :find
            end
          end
        end

        # Initialize a collection of resources
        #
        # @private
        def instantiate_collection(klass, parsed_data = {})
          records = klass.extract_array(parsed_data).map do |record|
            instantiate_record(klass, data: record)
          end
          Her::Collection.new(records, parsed_data[:metadata], parsed_data[:errors])
        end

        # Initialize a collection of resources with raw data from an HTTP request
        #
        # @param [Array] parsed_data
        # @private
        def new_collection(parsed_data)
          instantiate_collection(self, parsed_data)
        end

        # Initialize a new object with the "raw" parsed_data from the parsing middleware
        #
        # @private
        def new_from_parsed_data(parsed_data)
          instantiate_record(self, parsed_data)
        end

        # Use setter methods of model for each key / value pair in params
        # Return key / value pairs for which no setter method was defined on the
        # model
        #
        # @private
        def use_setter_methods(model, params = {})
          assoc_keys = model.class.association_keys
          reserved = [:id, model.class.primary_key, *assoc_keys]
          model.class.attributes *(params.keys - reserved)

          setter_method_names = model.class.setter_method_names
          params.each_with_object({}) do |(key, value), memo|
            setter_method = "#{key}="
            if setter_method_names.include?(setter_method) && (!assoc_keys.include?(key) || (!value.is_a?(Hash) && Array(value).any? { |v| !v.is_a?(Hash) }))
              model.send setter_method, value
            else
              memo[key.to_sym] = value
            end
          end
        end

        # Define attribute method matchers to automatically define them using
        # ActiveModel's define_attribute_methods.
        #
        # @private
        def define_attribute_method_matchers
          attribute_method_suffix '='
          attribute_method_suffix '?'
        end

        # Create a mutex for dynamically generated attribute methods or use one
        # defined by ActiveModel.
        #
        # @private
        def attribute_methods_mutex
          @attribute_methods_mutex ||= begin
            if generated_attribute_methods.respond_to? :mu_synchronize
              generated_attribute_methods
            else
              Mutex.new
            end
          end
        end

        # Define the attributes that will be used to track dirty attributes and
        # validations
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

        # Define the accessor in which the API response errors (obtained from
        # the parsing middleware) will be stored
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

        # Define the accessor in which the API response metadata (obtained from
        # the parsing middleware) will be stored
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
          @_her_setter_method_names ||= begin
            instance_methods.each_with_object(Set.new) do |method, memo|
              memo << method.to_s if method.to_s.end_with?('=')
            end
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
