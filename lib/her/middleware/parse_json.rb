require 'date'

module Her
  module Middleware
    class ParseJSON < Faraday::Response::Middleware
      # @private
      def parse_json(body = nil)
        body = '{}' if body.blank?
        message = "Response from the API must behave like a Hash or an Array (last JSON response was #{body.inspect})"

        json = begin
          MultiJson.load(body, :symbolize_keys => true)
        rescue MultiJson::LoadError
          raise Her::Errors::ParseError, message
        end

        raise Her::Errors::ParseError, message unless json.is_a?(Hash) or json.is_a?(Array)

        decode_object(json)
      end

      def decode_object(data)
        case data
        when Hash then decode_hash(data)
        when Array then data.map { |o| decode_object(o) }
        else data
        end
      end

      def decode_hash(hash)
        hash.keys.each do |key|
          hash[key.to_sym] = decode_hash_value(key, hash.delete(key))
        end
        hash
      end

      def decode_hash_value(key, value)
        if time_field?(key, value)
          if value.is_a?(String)
            begin
              Time.parse(value)
            rescue ArgumentError
              value
            end
          elsif value.is_a?(Integer) || value.is_a?(Float)
            Time.at(value)
          else
            value
          end
        elsif value.is_a?(Hash)
          decode_hash(value)
        elsif value.is_a?(Array)
          value.map { |o| decode_hash_value(key, o) }
        else
          value
        end
      end

      def time_field?(key, value)
        value && (key =~ /_(at|on)\z/ || key =~ /(\A|_)date\z/)
      end

    end
  end
end
