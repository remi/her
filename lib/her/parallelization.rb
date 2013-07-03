module Her
  module Parallelization
    def in_parallel
      parallelizer = Parallelizer.new
      yield parallelizer if block_given?
      return [] if parallelizer.queue.empty?
      responses = {}
      api = parallelizer.queue.first.parent.her_api
      api.connection.in_parallel do
        parallelizer.queue.each do |relation|
          responses[relation] = relation.fetch(true)
        end
      end
      merge_responses(responses)
    end

    private
    class Parallelizer
      def enqueue(relation)
        raise "You can only enqueue relation objects" unless relation.class == Her::Model::Relation
        queue << relation
      end
      alias add enqueue

      def queue
        @queue ||= []
      end
    end

    def merge_responses(responses)
      merged_responses = {}

      responses.each_pair do |relation, response|
        next unless response.env[:response].success?

        key = relation.parent.name.pluralize.underscore.to_sym
        value = relation.process_response(response.env[:body], response).to_a

        merged_responses[key] ||= []

        merged_responses[key] += value
      end

      return [] if merged_responses.empty?
      return merged_responses.values.first if merged_responses.values.count == 1
      merged_responses
    end
  end
end