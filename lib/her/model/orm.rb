module Her
  module Model
    # This module adds ORM-like capabilities to the model
    module ORM
      # Initialize a new object with data received from an HTTP request
      # @private
      def initialize(data) # {{{
        @data = data
        @data = self.class.parse_relationships(@data)
      end # }}}

      # Handles missing methods
      # @private
      def method_missing(method) # {{{
        method = method.to_s.gsub(/(\?|\!)$/, "").to_sym
        @data.include?(method) ? @data[method] : super
      end # }}}

      # Fetch a specific resource based on an ID
      def find(id) # {{{
        data, errors, metdata = request :method => :get, :path => "#{@her_collection_path}/#{id}"
        new(data)
      end # }}}
    end
  end
end
