module Her
  module Model
    module Serialization
      extend ActiveSupport::Concern
      include ActiveModel::Serializers::JSON

      def serializable_hash(options = nil)
        options = options.try(:dup) || {}

        options[:except] = Array(options[:except]).map(&:to_s)
        options[:except] |= self.class.association_names.map(&:to_s)

        super(options)
      end

      included do
        # Rails 3 defaulted to true but Her has always defaulted to
        # false. This can be dropped when Rails 3 support is dropped.
        self.include_root_in_json = false

        # Rails creates include_root_in_json as a class attribute but
        # Her previously had its own implementation combining the
        # getter and setter. This monstrosity tries to achieve
        # compatibility in the simplest way possible.
        class << self

          realias = proc do
            alias_method :include_root_in_json_getter, :include_root_in_json

            def include_root_in_json(value = nil)
              if value.nil?
                include_root_in_json_getter
              else
                self.include_root_in_json = value
              end
            end
          end

          realias.call
          alias_method :include_root_in_json_without_realias, :include_root_in_json=

          define_method :include_root_in_json= do |value|
            include_root_in_json_without_realias value
            realias.call
          end
        end
      end
    end
  end
end
