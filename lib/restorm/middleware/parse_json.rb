module Restorm
  module Middleware
    class ParseJSON < Faraday::Middleware

      # @private
      def parse_json(body = nil)
        body = '{}' if body.blank?
        message = "Response from the API must behave like a Hash or an Array (last JSON response was #{body.inspect})"

        json = begin
          MultiJson.load(body, :symbolize_keys => true)
        rescue MultiJson::LoadError
          raise Restorm::Errors::ParseError, message
        end

        raise Restorm::Errors::ParseError, message unless json.is_a?(Hash) || json.is_a?(Array)

        json
      end
    end
  end
end
