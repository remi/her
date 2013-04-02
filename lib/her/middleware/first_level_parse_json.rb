module Her
  module Middleware
    # This middleware treat the received first-level JSON structure as the resource data.
    class FirstLevelParseJSON < Faraday::Response::Middleware
      # Parse the response body
      #
      # @param [String] body The response body
      # @return [Mixed] the parsed response
      def parse(body)
        json = MultiJson.load(body, :symbolize_keys => true)
        raise Her::Errors::ParseError, "Response from the API must behave like a Hash or an Array (last was: #{json.inspect})" unless json.is_a?(Hash) or json.is_a?(Array)

        errors = json.delete(:errors) || {}
        metadata = json.delete(:metadata) || []
        {
          :data => json,
          :errors => errors,
          :metadata => metadata
        }
      end

      # This method is triggered when the response has been received. It modifies
      # the value of `env[:body]`.
      #
      # @param [Hash] env The response environment
      def on_complete(env)
        case env[:status]
        when 204
          env[:body] = parse('{}')
        else
          env[:body] = parse(env[:body])
        end
      end
    end
  end
end
