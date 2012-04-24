module Her
  module Model
    module Introspection
      # Inspect an element, returns it for introspection.
      #
      # @example
      #   class User
      #     include Her::Model
      #   end
      #
      #   @user = User.find(1)
      #   p @user # => #<User(/users/1) id=1 name="Tobias Fünke">
      def inspect # {{{
        resource_path = self.class.collection_path
        resource_path << "/#{id}" if @data.include?(:id)
        "#<#{self.class}(#{resource_path}) #{@data.inject([]) { |memo, item| key, value = item; memo << "#{key}=#{attribute_for_inspect(value)}"}.join(" ")}>"
      end # }}}

      private
      # @private
      def attribute_for_inspect(value) # {{{
        if value.is_a?(String) && value.length > 50
          "#{value[0..50]}...".inspect
        elsif value.is_a?(Date) || value.is_a?(Time)
          %("#{value}")
        else
          value.inspect
        end
      end # }}}
    end
  end
end
