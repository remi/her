module Her
  module Middleware
    # This middleware expects the resource/collection data to be contained in the `data`
    # key of the JSON object
    class SecondLevelParseJSON < ParseJSON
      # Parse the response body
      #
      # @param [String] body The response body
      # @return [Mixed] the parsed response
      def parse(body)
        json = parse_json(body)

        {
          :data => json[:data],
          :errors => json[:errors],
          :metadata => json[:metadata]
        }
      end

      # This method is triggered when the response has been received. It modifies
      # the value of `env[:body]`.
      #
      # @param [Hash] env The response environment
      def on_complete(env)
        env[:body] = parse(env[:body])
      end
    end
  end
end
