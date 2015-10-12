module Her
  module Model
    module Serialization
      # Return JSON serialized string representing the model
      #
      # @params options [Hash] options to select the contents of the returned String,
      #   note that the values in the options can be Strings or Symbols
      # @option options :only [String|Array<String>] the name or a list of names
      #   of attributes to include to the exclusion of all others
      # @option options :execpt [String|Array<String>] the name or a list of
      #   names of attributes to exclude from the returned String
      # @option options :methods [String|Array<String>] the name or a list of
      #   names of methods to include in addition to the attributes
      #
      # @example
      #   class User
      #     include Her::Model
      #   end
      #
      #   @user = User.find(1)
      #   p @user.to_json # => '{"id":1,"name":"Tobias Fünke"}'
      #   p @user.to_json(only: "name") # => '{"name":"Tobias Fünke"}'
      def to_json(options = {})
        as_json(options).to_json
      end

      # Return a Hash representing the model, preparing for JSON serialization
      #
      # @see #to_json
      #   for list of allowable options
      def as_json(options = {})
        options = options.symbolize_keys

        if options.key?(:only)
          hash = attributes.slice(*Array.wrap(options[:only]).map(&:to_s))
        elsif options.key?(:except)
          exclude_keys = Array.wrap(options[:except]).map(&:to_s)
          hash = attributes.reject { |key, _value| exclude_keys.include?(key) }
        else
          hash = attributes.dup
        end

        Array.wrap(options[:methods]).each { |method| hash[method.to_s] = send(method) }

        hash
      end
    end
  end
end
