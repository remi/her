module Her
  module Model
    # @private
    module DeprecatedMethods
      extend ActiveSupport::Concern

      def data(*args)
        Her::Deprecation.replace_method! :data, :attributes, self, *args
      end

      def data=(*args)
        Her::Deprecation.replace_method! :data=, :attributes=, self, *args
      end

      def update_attributes(*args)
        Her::Deprecation.replace_method! :update_attributes, :assign_attributes, self, *args
      end

      def assign_data(*args)
        Her::Deprecation.replace_method! :assign_data, :assign_attributes, self, *args
      end

      def has_data?(*args)
        Her::Deprecation.replace_method! :has_data?, :has_attribute?, self, *args
      end

      def get_data(*args)
        Her::Deprecation.replace_method! :get_data, :get_attribute, self, *args
      end

      module ClassMethods
        def has_relationship?(*args)
          Her::Deprecation.replace_method! :has_relationship?, :has_association?, self, *args
        end

        def get_relationship(*args)
          Her::Deprecation.replace_method! :get_relationship, :get_association, self, *args
        end

        def relationships(*args)
          Her::Deprecation.replace_method! :relationships, :associations, self, *args
        end

        def her_api(*args)
          Her::Deprecation.replace_method! :her_api, :use_api, self, *args
        end
      end
    end
  end
end
