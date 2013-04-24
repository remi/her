module Her
  module Middleware
    # This middleware adds a "Accept: application/json" HTTP header
    class AcceptJSON < Faraday::Middleware
      # @private
      def add_header(headers)
        headers.merge! "Accept" => "application/json"
      end

      # @private
      def call(env)
        add_header(env[:request_headers])
        @app.call(env)
      end
    end
  end
end
