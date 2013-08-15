module Her
  module Model
    # This Module manages inline caching functionality
    module InlineCaching
      extend ActiveSupport::Concern

      module ClassMethods

        # Disable inline caching of responses if another cache method is used or when using inherited_resources
        #
        # @example
        #
        #   class User
        #     include Her::Model
        #     disable_inline_caching
        #   end
        def disable_inline_caching
          @_inline_caching_disabled = true
        end

        # @private
        def inline_caching_disabled?
          @_inline_caching_disabled || false
        end

      end

    end
  end
end