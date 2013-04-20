module Her
  module Model
    class Relation
      attr_accessor :query_attrs

      # @private
      def initialize(parent)
        @parent = parent
        @query_attrs = {}
      end

      # Build a new resource
      def build(attrs = {})
        @parent.new(@query_attrs.merge(attrs))
      end

      # Add a query string parameter
      def where(attrs = {})
        return self if attrs.blank?
        self.clone.tap { |a| a.query_attrs = a.query_attrs.merge(attrs) }
      end
      alias :all :where

      def page(page)
        where(:page => page)
      end

      def per_page(per_page)
        where(:per_page => per_page)
      end
      alias :per :per_page

      # Bubble all methods to the fetched collection
      def method_missing(method, *args, &blk)
        fetch.send(method, *args, &blk)
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
      # @example
      #   @users = User.all
      #   # Fetched via GET "/users"
      #
      # @example
      #   @users = User.where(:approved => 1).all
      #   # Fetched via GET "/users?approved=1"
      def fetch
        @_fetch ||= begin
          path = @parent.build_request_path(@query_attrs)
          @parent.request(@query_attrs.merge(:_method => :get, :_path => path)) do |parsed_data, response|
            @parent.new_collection(parsed_data)
          end
        end
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
      def create(attrs = {})
        resource = @parent.new(@query_attrs.merge(attrs))
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
      def first_or_create(attrs = {})
        fetch.first || create(attrs)
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
      def first_or_initialize(attrs = {})
        fetch.first || build(attrs)
      end
    end
  end
end
