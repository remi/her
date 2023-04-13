module Restorm
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
        Restorm::Model::DeprecatedMethods.deprecate! :data, :attributes, self, *args
      end

      def data=(*args)
        Restorm::Model::DeprecatedMethods.deprecate! :data=, :attributes=, self, *args
      end

      def update_attributes(*args)
        Restorm::Model::DeprecatedMethods.deprecate! :update_attributes, :assign_attributes, self, *args
      end

      def assign_data(*args)
        Restorm::Model::DeprecatedMethods.deprecate! :assign_data, :assign_attributes, self, *args
      end

      def has_data?(*args)
        Restorm::Model::DeprecatedMethods.deprecate! :has_data?, :has_attribute?, self, *args
      end

      def get_data(*args)
        Restorm::Model::DeprecatedMethods.deprecate! :get_data, :get_attribute, self, *args
      end

      module ClassMethods
        def has_relationship?(*args)
          Restorm::Model::DeprecatedMethods.deprecate! :has_relationship?, :has_association?, self, *args
        end

        def get_relationship(*args)
          Restorm::Model::DeprecatedMethods.deprecate! :get_relationship, :get_association, self, *args
        end

        def relationships(*args)
          Restorm::Model::DeprecatedMethods.deprecate! :relationships, :associations, self, *args
        end

        def her_api(*args)
          Restorm::Model::DeprecatedMethods.deprecate! :restorm_api, :use_api, self, *args
        end
      end
    end
  end
end
