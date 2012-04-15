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
        if @data.include?(method)
          if attrs and assignment_method
            @data[method.to_s.gsub(/\=$/, "").to_sym] = attrs
          else
            @data[method]
          end
        else
          super
        end
      end # }}}

      # Initialize a collection of resources with raw data from an HTTP request
      def new_collection(parsed_data) # {{{
        collection_data = parsed_data[:data]
        Her::Model::ORM.initialize_collection(self.to_s.downcase.to_sym, collection_data)
      end # }}}

      # Fetch a specific resource based on an ID
      #
      # @example
      #   @user = User.find(1) GET /users/1
      def find(id, params={}) # {{{
        request(params.merge(:_method => :get, :_path => "#{@her_collection_path}/#{id}")) do |parsed_data|
          new(parsed_data[:data])
        end
      end # }}}

      # Fetch a collection of resources
      #
      # @example
      #   @users = User.all # GET /users
      def all(params={}) # {{{
        request(params.merge(:_method => :get, :_path => "#{@her_collection_path}")) do |parsed_data|
          new_collection(parsed_data)
        end
      end # }}}

      # Create a resource and return it
      #
      # @example
      #   @user = User.create({ :fullname => "Tobias Fünke" }) # POST /users/1
      def create(params={}) # {{{
        request(params.merge(:_method => :post, :_path => "#{@her_collection_path}")) do |parsed_data|
          new(parsed_data[:data])
        end
      end # }}}

      # Save an existing resource and return it
      #
      # @example
      #   @user = User.save_existing(1, { :fullname => "Tobias Fünke" }) # PUT /users/1
      def save_existing(id, params) # {{{
        request(params.merge(:_method => :put, :_path => "#{collection_path}/#{id}")) do |parsed_data|
          new(parsed_data[:data])
        end
      end # }}}

      # Save a resource
      #
      # @example Save a resource after fetching it
      #   @user = User.find(1) # GET /users/1
      #   @user.fullname = "Tobias Fünke"
      #   @user.save # PUT /users/1
      #
      # @example Save a new resource by creating it
      #   @user = User.new({ :fullname => "Tobias Fünke" })
      #   @user.save # POST /users
      def save # {{{
        params = @data.dup
        if @data[:id]
          self.class.perform_hook(self, :before, :update)
          self.class.perform_hook(self, :before, :save)
          self.class.request(params.merge(:_method => :put, :_path => "#{self.class.collection_path}/#{id}")) do |parsed_data|
            @data = parsed_data[:data]
          end
          resource = self
        else
          self.class.perform_hook(self, :before, :create)
          self.class.perform_hook(self, :before, :save)
          resource = self.class.create(params)
          self.class.perform_hook(resource, :after, :save)
          self.class.perform_hook(resource, :after, :create)
        end
        resource
      end # }}}

      # Destroy a resource
      #
      # @example
      #   @user = User.find(1) # GET /users/1
      #   @user.destroy # DELETE /users/1
      def destroy # {{{
        params = @data.dup
        self.class.perform_hook(self, :before, :destroy)
        self.class.request(params.merge(:_method => :delete, :_path => "#{self.class.collection_path}/#{id}")) do |parsed_data|
          @data = parsed_data[:data]
        end
        self.class.perform_hook(self, :after, :destroy)
        self
      end # }}}

      # Destroy an existing resource
      #
      # @example
      #   User.destroy_existing(1) # DELETE /users/1
      def destroy_existing(id) # {{{
        params = {}
        request(params.merge(:_method => :delete, :_path => "#{collection_path}/#{id}")) do |parsed_data|
          new(parsed_data[:data])
        end
      end # }}}
    end
  end
end
