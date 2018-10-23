module Her
  module Model
    module Introspection
      extend ActiveSupport::Concern
      # Inspect an element, returns it for introspection.
      #
      # @example
      #   class User
      #     include Her::Model
      #   end
      #
      #   @user = User.find(1)
      #   p @user # => #<User(/users/1) id=1 name="Tobias Fünke">
      def inspect
        first = Thread.current[:her_inspect_objects].nil?
        Thread.current[:her_inspect_objects] = [] if first

        resource_path = begin
          request_path
        rescue Her::Errors::PathError => e
          joined = e.missing_parameters.map { |m| "`#{m}`" }.join(", ")
          "<unknown path, missing #{joined}>"
        end

        result = "#<#{self.class}(#{resource_path}) "

        if Thread.current[:her_inspect_objects].include?(self)
          result << '...>'
        else
          Thread.current[:her_inspect_objects] << self
          result << attributes.keys.map { |k| "#{k}=#{attribute_for_inspect(send(k))}" }.join(' ') + '>'
        end
      ensure
        Thread.current[:her_inspect_objects] = nil if first
      end

      private

      def attribute_for_inspect(value)
        if value.is_a?(String) && value.length > 50
          "#{value[0..50]}...".inspect
        elsif value.is_a?(Date) || value.is_a?(Time)
          %("#{value}")
        else
          value.inspect
        end
      end

      # @private
      module ClassMethods
        # Finds a class at the same level as this one or at the global level.
        #
        # @private
        def her_nearby_class(name)
          her_sibling_class(name) || name.constantize
        end

        protected

        # Looks for a class at the same level as this one with the given name.
        #
        # @private
        def her_sibling_class(name)
          if mod = her_containing_module
            @_her_sibling_class ||= Hash.new { Hash.new }
            @_her_sibling_class[mod][name] ||= "#{mod.name}::#{name}".constantize rescue nil
          end
        end

        # If available, returns the containing Module for this class.
        #
        # @private
        def her_containing_module
          return unless name =~ /::/
          name.split("::")[0..-2].join("::").constantize
        end
      end
    end
  end
end
