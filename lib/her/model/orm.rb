module Her
  module Model
    # This module adds ORM-like capabilities to the model
    module ORM
      extend ActiveSupport::Concern
      attr_accessor :data, :metadata, :errors
      alias :attributes :data
      alias :attributes= :data=

      # Initialize a new object with data received from an HTTP request
      def initialize(params={})
        @data = {}
        @metadata = params.delete(:_metadata) || {}
        @errors = params.delete(:_errors) || {}

        # Use setter methods first, then translate attributes of relationships
        # into relationship instances, then merge the parsed_data into @data.
        unset_data = Her::Model::ORM.use_setter_methods(self, params)
        parsed_data = self.class.parse_relationships(unset_data)
        @data.update(parsed_data)
      end

      # Initialize a collection of resources
      # @private
      def self.initialize_collection(klass, parsed_data={})
        collection_data = parsed_data[:data].map { |item_data| klass.new(item_data) }
        Her::Collection.new(collection_data, parsed_data[:metadata], parsed_data[:errors])
      end

      # Use setter methods of model for each key / value pair in params
      # Return key / value pairs for which no setter method was defined on the model
      # @private
      def self.use_setter_methods(model, params)
        setter_method_names = model.class.setter_method_names
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

      # Handles missing methods by routing them through @data
      # @private
      def method_missing(method, *args, &blk)
        if method.to_s.end_with?('=')
          @data[method.to_s.chomp('=').to_sym] = args.first
        elsif method.to_s.end_with?('?')
          @data.include?(method.to_s.chomp('?').to_sym)
        elsif @data.include?(method)
          @data[method]
        else
          super
        end
      end

      # Handles returning true for the cases handled by method_missing
      def respond_to?(method, include_private = false)
        method.to_s.end_with?('=') || method.to_s.end_with?('?') || @data.include?(method) || super
      end

      # Assign new data to an instance
      def assign_data(new_data)
        new_data = Her::Model::ORM.use_setter_methods(self, new_data)
        @data.update new_data
      end
      alias :assign_attributes :assign_data

      # Handles returning true for the accessible attributes
      def has_data?(attribute_name)
        @data.include?(attribute_name)
      end

      # Handles returning attribute value from data
      def get_data(attribute_name)
        @data[attribute_name]
      end

      # Override the method to prevent from returning the object ID (in ruby-1.8.7)
      # @private
      def id
        @data[:id] || super
      end

      # Return `true` if a resource was not saved yet
      def new?
        !@data.include?(:id)
      end

      # Return `true` if a resource does not contain errors
      def valid?
        @errors.empty?
      end

      # Return `true` if a resource contains errors
      def invalid?
        @errors.any?
      end

      # Return `true` if the other object is also a Her::Model and has matching data
      def ==(other)
        other.is_a?(Her::Model) && @data == other.data
      end

      # Delegate to the == method
      def eql?(other)
        self == other
      end

      # Delegate to @data, allowing models to act correctly in code like:
      #     [ Model.find(1), Model.find(1) ].uniq # => [ Model.find(1) ]
      def hash
        @data.hash
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

        if @data[:id]
          hooks = [:update, :save]
          method = :put
        else
          hooks = [:create, :save]
          method = :post
        end

        self.class.wrap_in_hooks(resource, *hooks) do |resource, klass|
          klass.request(params.merge(:_method => method, :_path => "#{request_path}")) do |parsed_data|
            self.data = parsed_data[:data] if parsed_data[:data].any?
            self.metadata = parsed_data[:metadata]
            self.errors = parsed_data[:errors]

            return false if self.errors.any?
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
        self.class.wrap_in_hooks(resource, :destroy) do |resource, klass|
          klass.request(:_method => :delete, :_path => "#{request_path}") do |parsed_data|
            self.data = parsed_data[:data]
            self.metadata = parsed_data[:metadata]
            self.errors = parsed_data[:errors]
          end
        end
        self
      end

      # Convert into a hash of request parameters
      #
      # @example
      #   @user.to_params
      #   # => { :id => 1, :name => 'John Smith' }
      def to_params
        @data.dup
      end

      module ClassMethods
        # Initialize a collection of resources with raw data from an HTTP request
        #
        # @param [Array] parsed_data
        def new_collection(parsed_data)
          Her::Model::ORM.initialize_collection(self, parsed_data)
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
            request(params.merge(:_method => :get, :_path => "#{build_request_path(params.merge(:id => id))}")) do |parsed_data|
              new(parsed_data[:data].merge :_metadata => parsed_data[:data], :_errors => parsed_data[:errors])
            end
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
          request(params.merge(:_method => :get, :_path => "#{build_request_path(params)}")) do |parsed_data|
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
          wrap_in_hooks(resource, :create, :save) do |resource, klass|
            params = resource.to_params
            request(params.merge(:_method => :post, :_path => "#{build_request_path(params)}")) do |parsed_data|
              resource.instance_eval do
                @data = parsed_data[:data]
                @metadata = parsed_data[:metadata]
                @errors = parsed_data[:errors]
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
          resource = new(params.merge(:id => id))
          resource.save
          resource
        end

        # Destroy an existing resource
        #
        # @example
        #   User.destroy_existing(1)
        #   # Called via DELETE "/users/1"
        def destroy_existing(id, params={})
          request(params.merge(:_method => :delete, :_path => "#{build_request_path(params.merge(:id => id))}")) do |parsed_data|
            new(parsed_data[:data])
          end
        end

        # @private
        def setter_method_names
          @setter_method_names ||= instance_methods.inject(Set.new) do |memo, method_name|
            memo << method_name.to_s if method_name.to_s.end_with?('=')
            memo
          end
        end
      end
    end
  end
end
