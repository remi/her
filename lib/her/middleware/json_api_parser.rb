module Her
  module Middleware
    # This middleware requires the resource/collection
    # data to be contained in the `data` key of the JSON object
    class JsonApiParser < ParseJSON
      # Parse the response body
      #
      # @param [String] body The response body
      # @return [Mixed] the parsed response
      # @private
      def parse(body)
        json = parse_json(body)

        included = json.fetch(:included, [])
        primary_data = json.fetch(:data, {})
        Array.wrap(primary_data).each do |resource|
          resource_relationships = resource.delete(:relationships) { {} }
          resource[:attributes].merge!(populate_relationships(resource_relationships, included.dup))
        end

        {
          :data => primary_data || {},
          :errors => json[:errors] || [],
          :metadata => json[:meta] || {},
        }
      end

      def populate_relationships(relationships, included)
        return {} if included.empty?
        {}.tap do |built|
          relationships.each do |rel_name, linkage|
            linkage_data = linkage.fetch(:data, {})
            built_relationship = if linkage_data.is_a? Array
              linkage_data.map { |l| included.detect { |i| i.values_at(:id, :type) == l.values_at(:id, :type) } }.compact
            else
              included.detect { |i| i.values_at(:id, :type) == linkage_data.values_at(:id, :type) }
            end

            built[rel_name] = built_relationship
          end
        end
      end

      # This method is triggered when the response has been received. It modifies
      # the value of `env[:body]`.
      #
      # @param [Hash] env The response environment
      # @private
      def on_complete(env)
        env[:body] = case env[:status]
        when 204
          {
            :data => {},
            :errors => [],
            :metadata => {},
          }
        else
          parse(env[:body])
        end
      end
    end
  end
end
