module Her
  module Middleware
    # This is the default middleware used to parse JSON responses. It returns
    # a Hash with three elements: `data`, `errors` and `metadata`.
    class DefaultParseJSON < Faraday::Response::Middleware
      # Parse the response body
      #
      # @param [String] body The response body
      # @return [Mixed] the parsed response
      def parse(body) # {{{
        json = MultiJson.load(body, :symbolize_keys => true)
        {
          :data => json[:data],
          :errors => json[:errors],
          :metadata => json[:metadata]
        }
      end # }}}

      # This method is triggered when the response has been received. It modifies
      # the value of `env[:body]`.
      #
      # @param [Hash] env The response environment
      def on_complete(env) # {{{
        env[:body] = parse(env[:body])
      end # }}}
    end
  end
end
