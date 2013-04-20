module Her
  module Testing
    module Macros
      def ok!(body)
        [200, {}, body.to_json]
      end

      def error!(body)
        [400, {}, body.to_json]
      end

      def params(env)
        Faraday::Utils.parse_query(env[:body])
      end
    end
  end
end
