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
          @params ||= begin
            parsed_query = Faraday::Utils.parse_nested_query(env[:body])

            if parsed_query
              parsed_query.with_indifferent_access.merge(env[:params])
            else
              env[:params].with_indifferent_access
            end
          end
        end
      end
    end
  end
end
