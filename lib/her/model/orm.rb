module Her
  module Model
    # This module adds ORM-like capabilities to the model
    module ORM
      extend ActiveSupport::Concern
      attr_accessor :attributes, :metadata, :response_errors
      alias :data :attributes
      alias :data= :attributes=

      # Initialize a new object with data received from an HTTP request
      def initialize(attributes={})
        attributes ||= {}
        @metadata = attributes.delete(:_metadata) || {}
        @response_errors = attributes.delete(:_errors) || {}
        @destroyed = attributes.delete(:_destroyed) || false

        update_attributes(attributes)
      end

      # Initialize a collection of resources
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

      # Handles returning true for the cases handled by method_missing
      def respond_to?(method, include_private = false)
        method.to_s.end_with?('=') || method.to_s.end_with?('?') || @attributes.include?(method) || super
      end

      def respond_to_missing?(method, include_private = false)
        method.to_s.end_with?('=') || method.to_s.end_with?('?') || @attributes.include?(method) || @attributes.include?(method) || super
      end

      # Assign new data to an instance
      def assign_attributes(new_attributes)
        new_attributes = Her::Model::ORM.use_setter_methods(self, new_attributes)
        attributes.update new_attributes
      end
      alias :assign_data :assign_attributes

      # Handles returning true for the accessible attributes
      def has_attribute?(attribute_name)
        attributes.include?(attribute_name)
      end
      alias :has_data? :has_attribute?

      def get_attribute(attribute_name)
        attributes[attribute_name]
      end
      alias :get_data :get_attribute

      # Override the method to prevent from returning the object ID (in ruby-1.8.7)
      # @private
      def id
        attributes[self.class.primary_key] || super
      end

      # Return `true` if a resource was not saved yet
      def new?
        !attributes.include?(self.class.primary_key)
      end

      # Return `true` if the other object is also a Her::Model and has matching data
      def ==(other)
        other.is_a?(Her::Model) && attributes == other.attributes
      end

      # Delegate to the == method
      def eql?(other)
        self == other
      end

      # Delegate to @attributes, allowing models to act correctly in code like:
      #     [ Model.find(1), Model.find(1) ].uniq # => [ Model.find(1) ]
      def hash
        attributes.hash
      end

      # Return whether the object has been destroyed
      def destroyed?
        @destroyed
      end

      # Save a resource
      #
      # @example Save a resource after fetching it
      #   @user = User.find(1)
      #   # Fetched via GET "/users/1"
      #   @user.fullname = "Tobias Fünke"
      #   @user.save
      #   # Called via PUT "/users/1"
      #
      # @example Save a new resource by creating it
      #   @user = User.new({ :fullname => "Tobias Fünke" })
      #   @user.save
      #   # Called via POST "/users"
      def save
        params = to_params
        resource = self

        if new?
          callback = :create
          method = :post
        else
          callback = :update
          method = :put
        end

        run_callbacks callback do
          run_callbacks :save do
            self.class.request(params.merge(:_method => method, :_path => "#{request_path}")) do |parsed_data, response|
              update_attributes(self.class.parse(parsed_data[:data])) if parsed_data[:data].any?
              self.metadata = parsed_data[:metadata]
              self.response_errors = parsed_data[:errors]
              self.changed_attributes.clear if self.changed_attributes.present?

              return false if !response.success? || self.response_errors.any?
            end
          end
        end

        self
      end

      # Destroy a resource
      #
      # @example
      #   @user = User.find(1)
      #   @user.destroy
      #   # Called via DELETE "/users/1"
      def destroy
        resource = self
        run_callbacks :destroy do
          self.class.request(:_method => :delete, :_path => "#{request_path}") do |parsed_data, response|
            update_attributes(self.class.parse(parsed_data[:data])) if parsed_data[:data].any?
            self.metadata = parsed_data[:metadata]
            self.response_errors = parsed_data[:errors]
            @destroyed = true
          end
        end
        self
      end

      # @private
      def update_attributes(raw_data)
        @attributes ||= {}
        # Use setter methods first, then translate attributes of associations
        # into association instances, then merge the parsed_data into @attributes.
        unset_attributes = Her::Model::ORM.use_setter_methods(self, raw_data)
        parsed_attributes = self.class.parse_associations(unset_attributes)
        attributes.update(parsed_attributes)
      end

      # Convert into a hash of request parameters
      #
      # @example
      #   @user.to_params
      #   # => { :id => 1, :name => 'John Smith' }
      def to_params
        if self.class.include_root_in_json
          { (self.class.include_root_in_json == true ? self.class.root_element : self.class.include_root_in_json) => attributes.dup }
        else
          attributes.dup
        end
      end

      module ClassMethods
        # Initialize a collection of resources with raw data from an HTTP request
        #
        # @param [Array] parsed_data
        def new_collection(parsed_data)
          Her::Model::ORM.initialize_collection(self, parsed_data)
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

        # Parse data before assigning it to a resource
        #
        # @param [Hash] data
        def parse(data)
          if parse_root_in_json
            parse_root_in_json == true ? data[root_element.to_sym] : data[parse_root_in_json]
          else
            data
          end
        end

        # Fetch specific resource(s) by their ID
        #
        # @example
        #   @user = User.find(1)
        #   # Fetched via GET "/users/1"
        #
        # @example
        #   @users = User.find([1, 2])
        #   # Fetched via GET "/users/1" and GET "/users/2"
        def find(*ids)
          params = ids.last.is_a?(Hash) ? ids.pop : {}
          results = ids.flatten.compact.uniq.map do |id|
            resource = nil
            request(params.merge(:_method => :get, :_path => "#{build_request_path(params.merge(primary_key => id))}")) do |parsed_data, response|
              if response.success?
                resource = new(parse(parsed_data[:data]).merge :_metadata => parsed_data[:metadata], :_errors => parsed_data[:errors])
                resource.run_callbacks :find
              else
                return nil
              end
            end
            resource
          end
          if ids.length > 1 || ids.first.kind_of?(Array)
            results
          else
            results.first
          end
        end

        # Fetch a collection of resources
        #
        # @example
        #   @users = User.all
        #   # Fetched via GET "/users"
        def all(params={})
          request(params.merge(:_method => :get, :_path => "#{build_request_path(params)}")) do |parsed_data, response|
            new_collection(parsed_data)
          end
        end

        # Create a resource and return it
        #
        # @example
        #   @user = User.create({ :fullname => "Tobias Fünke" })
        #   # Called via POST "/users/1"
        def create(params={})
          resource = new(params)
          resource.run_callbacks :create do
            resource.run_callbacks :save do
              params = resource.to_params
              request(params.merge(:_method => :post, :_path => "#{build_request_path(params)}")) do |parsed_data, response|
                data = parse(parsed_data[:data])
                resource.instance_eval do
                  update_attributes(data)
                  @metadata = parsed_data[:metadata]
                  @response_errors = parsed_data[:errors]
                  @changed_attributes.clear if @changed_attributes.present?
                end
              end
            end
          end
          resource
        end

        # Save an existing resource and return it
        #
        # @example
        #   @user = User.save_existing(1, { :fullname => "Tobias Fünke" })
        #   # Called via PUT "/users/1"
        def save_existing(id, params)
          resource = new(params.merge(primary_key => id))
          resource.save
          resource
        end

        # Destroy an existing resource
        #
        # @example
        #   User.destroy_existing(1)
        #   # Called via DELETE "/users/1"
        def destroy_existing(id, params={})
          request(params.merge(:_method => :delete, :_path => "#{build_request_path(params.merge(primary_key => id))}")) do |parsed_data, response|
            new(parse(parsed_data[:data]).merge(:_destroyed => true))
          end
        end

        # @private
        def setter_method_names
          @setter_method_names ||= instance_methods.inject(Set.new) do |memo, method_name|
            memo << method_name.to_s if method_name.to_s.end_with?('=')
            memo
          end
        end

        # Return or change the value of `include_root_in_json`
        def include_root_in_json(value=nil)
          return @include_root_in_json if value.nil?
          @include_root_in_json = value
        end

        # Return or change the value of `parse_root_in`
        def parse_root_in_json(value=nil)
          return @parse_root_in_json if value.nil?
          @parse_root_in_json = value
        end
      end
    end
  end
end
