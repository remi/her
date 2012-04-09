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

      # Handles missing methods
      # @private
      def method_missing(method) # {{{
        method = method.to_s.gsub(/(\?|\!)$/, "").to_sym
        @data.include?(method) ? @data[method] : super
      end # }}}

      # Fetch a specific resource based on an ID
      def find(id, params={}) # {{{
        request(params.merge(:_method => :get, :_path => "#{@her_collection_path}/#{id}")) do |parsed_data|
          new(parsed_data[:resource])
        end
      end # }}}

      # Fetch a collection of resources
      def all(params={}) # {{{
        request(params.merge(:_method => :get, :_path => "#{@her_collection_path}")) do |parsed_data|
          Her::Model::ORM.initialize_collection(to_s.downcase.pluralize, parsed_data[:resource])
        end
      end # }}}

      # Create a resource
      def create(params={}) # {{{
        request(params.merge(:_method => :post, :_path => "#{@her_collection_path}")) do |parsed_data|
          new(parsed_data[:resource])
        end
      end # }}}
    end
  end
end
