module Her
  module Model
    # @private
    module DeprecatedMethods
      extend ActiveSupport::Concern

      def self.deprecate!(old, new, object, *args)
        line = begin
          raise StandardError
        rescue StandardError => e
          e.backtrace[2]
        end

        warn "#{line} - The `#{old}` method is deprecated and may be removed soon. Please update your code with `#{new}` instead."
        object.send(new, *args)
      end

      def data(*args)
        Her::Model::DeprecatedMethods.deprecate! :data, :attributes, self, *args
      end

      def data=(*args)
        Her::Model::DeprecatedMethods.deprecate! :data=, :attributes=, self, *args
      end

      def update_attributes(*args)
        Her::Model::DeprecatedMethods.deprecate! :update_attributes, :assign_attributes, self, *args
      end

      def assign_data(*args)
        Her::Model::DeprecatedMethods.deprecate! :assign_data, :assign_attributes, self, *args
      end

      def has_data?(*args)
        Her::Model::DeprecatedMethods.deprecate! :has_data?, :has_attribute?, self, *args
      end

      def get_data(*args)
        Her::Model::DeprecatedMethods.deprecate! :get_data, :get_attribute, self, *args
      end

      module ClassMethods
        def has_relationship?(*args)
          Her::Model::DeprecatedMethods.deprecate! :has_relationship?, :has_association?, self, *args
        end

        def get_relationship(*args)
          Her::Model::DeprecatedMethods.deprecate! :get_relationship, :get_association, self, *args
        end

        def relationships(*args)
          Her::Model::DeprecatedMethods.deprecate! :relationships, :associations, self, *args
        end

        def her_api(*args)
          Her::Model::DeprecatedMethods.deprecate! :her_api, :use_api, self, *args
        end
      end
    end
  end
end
