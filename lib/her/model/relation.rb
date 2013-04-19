module Her
  module Model
    class Relation
      attr_accessor :query_attrs

      # @private
      def initialize(parent)
        @parent = parent
        @query_attrs = {}
      end

      # Add a query string parameter
      def where(attrs = {})
        return self if attrs.blank?
        self.clone.tap { |a| a.query_attrs = a.query_attrs.merge(attrs) }
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
      def all
        path = @parent.build_request_path(@query_attrs)
        @parent.request(@query_attrs.merge(:_method => :get, :_path => path)) do |parsed_data, response|
          @parent.new_collection(parsed_data)
        end
      end

      # Return the first resource of the collection returned by `all`
      def first
        all.first
      end

      # Return the last resource of the collection returned by `all`
      def last
        all.last
      end

      # Create a resource and return it
      #
      # @example
      #   @user = User.create(:fullname => "Tobias Fünke")
      #   # Called via POST "/users/1"
      def create(params={})
        resource = @parent.new(@query_attrs.merge(params))
        resource.save

        resource
      end
    end
  end
end
