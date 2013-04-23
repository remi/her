module Her
  module Model
    # This module includes basic functionnality to Her::Model
    module Base
      extend ActiveSupport::Concern

      # Returns true if attribute_name is
      # * in resource attributes
      # * an association
      #
      # @private
      def has_key?(attribute_name)
        has_attribute?(attribute_name) ||
        has_association?(attribute_name)
      end

      # Returns
      # * the value of the attribute_name attribute if it's in orm data
      # * the resource/collection corrsponding to attribute_name if it's an association
      #
      # @private
      def [](attribute_name)
        get_attribute(attribute_name) ||
        get_association(attribute_name)
      end

      # @private
      def singularized_resource_name
        self.class.name.split('::').last.tableize.singularize
      end
    end
  end
end
