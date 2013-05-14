module Her
  module Model
    class Relation
      # @private
      attr_accessor :params

      # @private
      def initialize(parent)
        @parent = parent
        @params = {}
      end

      # @private
      def apply_to(attributes)
        @params.merge(attributes)
      end

      # Build a new resource
      def build(attributes = {})
        @parent.build(@params.merge(attributes))
      end

      # Add a query string parameter
      #
      # @example
      #   @users = User.all
      #   # Fetched via GET "/users"
      #
      # @example
      #   @users = User.where(:approved => 1).all
      #   # Fetched via GET "/users?approved=1"
      def where(params = {})
        return self if params.blank? && !@_fetch.nil?
        self.clone.tap do |r|
          r.params = r.params.merge(params)
          r.clear_fetch_cache!
        end
      end
      alias all where

      # Bubble all methods to the fetched collection
      #
      # @private
      def method_missing(method, *args, &blk)
        fetch.send(method, *args, &blk)
      end

      # @private
      def respond_to?(method, *args)
        super || fetch.respond_to?(method, *args)
      end

      # @private
      def nil?
        fetch.nil?
      end

      # @private
      def kind_of?(thing)
        fetch.kind_of?(thing)
      end

      # Fetch a collection of resources
      #
      # @private
      def fetch
        @_fetch ||= begin
          path = @parent.build_request_path(@params)
          method = @parent.method_for(:find)
          @parent.request(@params.merge(:_method => method, :_path => path)) do |parsed_data, response|
            @parent.new_collection(parsed_data)
          end
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
        params = @params.merge(ids.last.is_a?(Hash) ? ids.pop : {})

        results = ids.flatten.compact.uniq.map do |id|
          resource = nil
          request_params = params.merge(
            :_method => @parent.method_for(:find),
            :_path => @parent.build_request_path(params.merge(@parent.primary_key => id))
          )

          @parent.request(request_params) do |parsed_data, response|
            if response.success?
              resource = @parent.new_from_parsed_data(parsed_data)
              resource.run_callbacks :find
            else
              return nil
            end
          end

          resource
        end

        ids.length > 1 || ids.first.kind_of?(Array) ? results : results.first
      end

      # Create a resource and return it
      #
      # @example
      #   @user = User.create(:fullname => "Tobias Fünke")
      #   # Called via POST "/users/1" with `&fullname=Tobias+Fünke`
      #
      # @example
      #   @user = User.where(:email => "tobias@bluth.com").create(:fullname => "Tobias Fünke")
      #   # Called via POST "/users/1" with `&email=tobias@bluth.com&fullname=Tobias+Fünke`
      def create(attributes = {})
        attributes ||= {}
        resource = @parent.new(@params.merge(attributes))
        resource.save

        resource
      end

      # Fetch a resource and create it if it's not found
      #
      # @example
      #   @user = User.where(:email => "remi@example.com").find_or_create
      #
      #   # Returns the first item of the collection if present:
      #   # GET "/users?email=remi@example.com"
      #
      #   # If collection is empty:
      #   # POST /users with `email=remi@example.com`
      def first_or_create(attributes = {})
        fetch.first || create(attributes)
      end

      # Fetch a resource and build it if it's not found
      #
      # @example
      #   @user = User.where(:email => "remi@example.com").find_or_initialize
      #
      #   # Returns the first item of the collection if present:
      #   # GET "/users?email=remi@example.com"
      #
      #   # If collection is empty:
      #   @user.email # => "remi@example.com"
      #   @user.new? # => true
      def first_or_initialize(attributes = {})
        fetch.first || build(attributes)
      end

      # @private
      def clear_fetch_cache!
        instance_variable_set(:@_fetch, nil)
      end
    end
  end
end
