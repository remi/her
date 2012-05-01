module Her
  module Model
    # This module adds ORM-like capabilities to the model
    module ORM
      # Initialize a new object with data received from an HTTP request
      # @private
      def initialize(single_data) # {{{
        @data = single_data
        @data = self.class.parse_relationships(@data)
      end # }}}

      # Initialize a collection of resources
      # @private
      def self.initialize_collection(name, collection_data) # {{{
        collection_data.map { |item_data| Object.const_get(name.to_s.classify).new(item_data) }
      end # }}}

      # Handles missing methods by routing them through @data
      # @private
      def method_missing(method, attrs=nil) # {{{
        assignment_method = method.to_s =~ /\=$/
        method = method.to_s.gsub(/(\?|\!|\=)$/, "").to_sym
        if attrs and assignment_method
          @data[method.to_s.gsub(/\=$/, "").to_sym] = attrs
        else
          if @data.include?(method)
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

      # Initialize a collection of resources with raw data from an HTTP request
      #
      # @param [Hash] parsed_data The raw `parsed_data` parsed from the HTTP response
      def new_collection(parsed_data) # {{{
        collection_data = parsed_data[:data]
        Her::Model::ORM.initialize_collection(self.to_s.downcase.to_sym, collection_data)
      end # }}}

      # Return `true` if a resource was not saved yet
      def new? # {{{
        !@data.include?(:id)
      end # }}}

      # Fetch a specific resource based on an ID
      #
      # @example
      #   @user = User.find(1)
      #   # Fetched via GET "/users/1"
      def find(id, params={}) # {{{
        request(params.merge(:_method => :get, :_path => "#{build_request_path(params.merge(:id => id))}")) do |parsed_data|
          new(parsed_data[:data])
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
        perform_hook(resource, :before, :create)
        perform_hook(resource, :before, :save)
        params = resource.instance_eval { @data }
        request(params.merge(:_method => :post, :_path => "#{build_request_path(params)}")) do |parsed_data|
          resource.instance_eval do
            @data = parsed_data[:data]
          end
        end
        perform_hook(resource, :after, :save)
        perform_hook(resource, :after, :create)

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
        params = @data.dup
        resource = self
        if @data[:id]
          self.class.class_eval do
            perform_hook(resource, :before, :update)
            perform_hook(resource, :before, :save)
          end
          self.class.request(params.merge(:_method => :put, :_path => "#{request_path}")) do |parsed_data|
            @data = parsed_data[:data]
          end
          self.class.class_eval do
            perform_hook(resource, :after, :save)
            perform_hook(resource, :after, :update)
          end
          self
        else
          self.class.class_eval do
            perform_hook(resource, :before, :create)
            perform_hook(resource, :before, :save)
          end
          self.class.request(params.merge(:_method => :post, :_path => "#{request_path}")) do |parsed_data|
            @data = parsed_data[:data]
          end
          self.class.class_eval do
            perform_hook(resource, :after, :save)
            perform_hook(resource, :after, :create)
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
        params = @data.dup
        resource = self
        self.class.class_eval { perform_hook(resource, :before, :destroy) }
        self.class.request(params.merge(:_method => :delete, :_path => "#{request_path}")) do |parsed_data|
          @data = parsed_data[:data]
        end
        self.class.class_eval { perform_hook(resource, :after, :destroy) }
        self
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
