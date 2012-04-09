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

      # Initialize a collection of resources with raw data from an HTTP request
      #
      # @example
      #   User.get("/users/popular") { |data| User.new_collection(data) }
      def new_collection(parsed_data) # {{{
        collection_data = parsed_data[:data]
        Her::Model::ORM.initialize_collection(self.to_s.downcase.to_sym, collection_data)
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

      # Fetch a specific resource based on an ID
      def find(id, params={}) # {{{
        request(params.merge(:_method => :get, :_path => "#{@her_collection_path}/#{id}")) do |parsed_data|
          new(parsed_data[:data])
        end
      end # }}}

      # Fetch a collection of resources
      def all(params={}) # {{{
        request(params.merge(:_method => :get, :_path => "#{@her_collection_path}")) do |parsed_data|
          Her::Model::ORM.initialize_collection(to_s.downcase.pluralize, parsed_data[:data])
        end
      end # }}}

      # Create a resource
      def create(params={}) # {{{
        request(params.merge(:_method => :post, :_path => "#{@her_collection_path}")) do |parsed_data|
          new(parsed_data[:data])
        end
      end # }}}

      # Save a resource
      def save # {{{
        params = @data.dup
        if @data[:id]
          self.class.request(params.merge(:_method => :put, :_path => "#{self.class.collection_path}/#{id}")) do |parsed_data|
            @data = parsed_data[:data]
          end
        else
          self.class.create(params)
        end
      end # }}}
    end
  end
end
