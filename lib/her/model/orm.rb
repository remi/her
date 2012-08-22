module Her
  module Model
    # This module adds ORM-like capabilities to the model
    module ORM
      attr_accessor :data, :metadata, :errors

      # Initialize a new object with data received from an HTTP request
      # @private
      def initialize(data={}) # {{{
        @data = {}
        @metadata = data.delete(:_metadata) || {}
        @errors = data.delete(:_errors) || {}
        cleaned_data = data.inject({}) do |memo, item|
          key, value = item
          send "#{key}=".to_sym, value unless value.nil?
          respond_to?("#{key}=") ? memo : memo.merge({ key => value })
        end
        @data.merge! self.class.parse_relationships(cleaned_data)
      end # }}}

      # Initialize a collection of resources
      # @private
      def self.initialize_collection(klass, parsed_data={}) # {{{
        collection_data = parsed_data[:data].map { |item_data| klass.new(item_data) }
        Her::Collection.new(collection_data, parsed_data[:metadata], parsed_data[:errors])
      end # }}}

      # Handles missing methods by routing them through @data
      # @private
      def method_missing(method, attrs=nil) # {{{
        assignment_method = method.to_s =~ /\=$/
        method = method.to_s.gsub(/(\?|\!|\=)$/, "").to_sym
        if !attrs.nil? and assignment_method
          @data ||= {}
          @data[method.to_s.gsub(/\=$/, "").to_sym] = attrs
        else
          if @data and @data.include?(method)
            @data[method]
          else
            super
          end
        end
      end # }}}

      # Override the method to prevent from returning the object ID (in ruby-1.8.7)
      # @private
      def id # {{{
        @data[:id] || super
      end # }}}

      # Return `true` if a resource was not saved yet
      def new? # {{{
        !@data.include?(:id)
      end # }}}

      # Return `true` if a resource does not contain errors
      def valid? # {{{
        @errors.empty?
      end # }}}

      # Return `true` if a resource contains errors
      def invalid? # {{{
        @errors.any?
      end # }}}

      # Return `true` if the other object is also a Her::Model and has matching data
      def ==(other) # {{{
        other.is_a?(Her::Model) && @data == other.data
      end # }}}

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
      def save # {{{
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
            self.data = parsed_data[:data]
            self.metadata = parsed_data[:metadata]
            self.errors = parsed_data[:errors]
          end
        end
        self
      end # }}}

      # Destroy a resource
      #
      # @example
      #   @user = User.find(1)
      #   @user.destroy
      #   # Called via DELETE "/users/1"
      def destroy # {{{
        resource = self
        self.class.wrap_in_hooks(resource, :destroy) do |resource, klass|
          klass.request(:_method => :delete, :_path => "#{request_path}") do |parsed_data|
            self.data = parsed_data[:data]
            self.metadata = parsed_data[:metadata]
            self.errors = parsed_data[:errors]
          end
        end
        self
      end # }}}

      # Convert into a hash of request parameters
      #
      # @example
      #   @user.to_params
      #   # => { :id => 1, :name => 'John Smith' }
      def to_params # {{{
        @data.dup
      end # }}}

      module ClassMethods
        # Initialize a collection of resources with raw data from an HTTP request
        #
        # @param [Array] parsed_data
        def new_collection(parsed_data) # {{{
          Her::Model::ORM.initialize_collection(self, parsed_data)
        end # }}}

        # Fetch specific resource(s) by their ID
        #
        # @example
        #   @user = User.find(1)
        #   # Fetched via GET "/users/1"
        #
        # @example
        #   @users = User.find(1, 2)
        #   # Fetched via GET "/users/1" and GET "/users/2"
        def find(*ids) # {{{
          params = ids.last.is_a?(Hash) ? ids.pop : {}
          results = ids.map do |id|
            request_params = params.merge(
              :_method => :get,
              :_path => "#{build_request_path(params.merge(:id => id))}"
            )
            request(request_params) do |parsed_data|
              new(parsed_data[:data])
            end
          end
          if ids.length == 1
            results.first
          else
            results
          end
        end # }}}

        # Fetch a collection of resources
        #
        # @example
        #   @users = User.all
        #   # Fetched via GET "/users"
        def all(params={}) # {{{
          request(params.merge(:_method => :get, :_path => "#{build_request_path(params)}")) do |parsed_data|
            new_collection(parsed_data)
          end
        end # }}}

        # Create a resource and return it
        #
        # @example
        #   @user = User.create({ :fullname => "Tobias Fünke" })
        #   # Called via POST "/users/1"
        def create(params={}) # {{{
          resource = new(params)
          wrap_in_hooks(resource, :create, :save) do |resource, klass|
            params = resource.to_params
            request(params.merge(:_method => :post, :_path => "#{build_request_path(params)}")) do |parsed_data|
              resource.data = parsed_data[:data]
              resource.metadata = parsed_data[:metadata]
              resource.errors = parsed_data[:errors]
            end
          end
          resource
        end # }}}

        # Save an existing resource and return it
        #
        # @example
        #   @user = User.save_existing(1, { :fullname => "Tobias Fünke" })
        #   # Called via PUT "/users/1"
        def save_existing(id, params) # {{{
          resource = new(params.merge(:id => id))
          resource.save
        end # }}}

        # Destroy an existing resource
        #
        # @example
        #   User.destroy_existing(1)
        #   # Called via DELETE "/users/1"
        def destroy_existing(id, params={}) # {{{
          request(params.merge(:_method => :delete, :_path => "#{build_request_path(params.merge(:id => id))}")) do |parsed_data|
            new(parsed_data[:data])
          end
        end # }}}
      end
    end
  end
end
