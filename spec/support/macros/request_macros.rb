module Her
  module Testing
    module Macros
      module RequestMacros
        def ok!(body)
          [200, {}, body.to_json]
        end

        def error!(body)
          [400, {}, body.to_json]
        end

        def params(env)
          @params ||= Faraday::Utils.parse_nested_query(env[:body]).with_indifferent_access.merge(env[:params])
        end
      end
    end
  end
end
