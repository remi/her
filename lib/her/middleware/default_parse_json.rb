module Her
  module Middleware
    class DefaultParseJSON < Faraday::Response::Middleware
      def parse(body)
        json = MultiJson.load(body, :symbolize_keys => true)
        {
          :data => json[:data],
          :errors => json[:errors],
          :metadata => json[:metadata]
        }
      end

      def on_complete(env)
        env[:body] = parse(env[:body])
      end
    end
  end
end
