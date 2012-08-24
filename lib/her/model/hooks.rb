module Her
  module Model
    # Her supports hooks/callbacks that are triggered whenever resources are created, updated or destroyed.
    #
    # @example Defining a hook with a block
    #   class User
    #     include Her::Model
    #     before_save { |resource| resource.internal_id = 42 }
    #   end
    #
    # @example Defining a hook with a method name
    #   class User
    #     include Her::Model
    #     before_save :set_internal_id
    #
    #     private
    #     def set_internal_id
    #       self.internal_id = 42
    #     end
    #   end
    module Hooks
      # Add a *before save* callback. Triggered before a resource is created or updated.
      # @param [Symbol, &block] method A method or a block to be called
      def before_save(method=nil, &block); set_hook(:before, :save, method || block); end

      # Add a *before create* callback. Triggered before a resource is created.
      # @param [Symbol, &block] method A method or a block to be called
      def before_create(method=nil, &block); set_hook(:before, :create, method || block); end

      # Add a *before update* callback. Triggered before a resource is updated.
      # @param [Symbol, &block] method A method or a block to be called
      def before_update(method=nil, &block); set_hook(:before, :update, method || block); end

      # Add a *before destroy* callback. Triggered before a resource is destroyed.
      # @param [Symbol, &block] method A method or a block to be called
      def before_destroy(method=nil, &block); set_hook(:before, :destroy, method || block); end

      # Add a *after save* callback. Triggered after a resource is created or updated.
      # @param [Symbol, &block] method A method or a block to be called
      def after_save(method=nil, &block); set_hook(:after, :save, method || block); end

      # Add a *after create* callback. Triggered after a resource is created.
      # @param [Symbol, &block] method A method or a block to be called
      def after_create(method=nil, &block); set_hook(:after, :create, method || block); end

      # Add a *after update* callback. Triggered after a resource is updated.
      # @param [Symbol, &block] method A method or a block to be called
      def after_update(method=nil, &block); set_hook(:after, :update, method || block); end

      # Add a *after destroy* callback. Triggered after a resource is destroyed.
      # @param [Symbol, &block] method A method or a block to be called
      def after_destroy(method=nil, &block); set_hook(:after, :destroy, method || block); end

      # Wrap a block between “before” and “after” hooks
      # @private
      def wrap_in_hooks(resource, *hooks) # {{{
        perform_before_hooks(resource, *hooks)
        yield(resource, resource.class)
        perform_after_hooks(resource, *hooks.reverse)
      end # }}}

      # @private
      def hooks # {{{
        @her_hooks ||= begin
          if superclass.respond_to?(:hooks)
            superclass.hooks.dup
          else
            {}
          end
        end
      end # }}}

      private

      # @private
      def set_hook(time, name, action) # {{{
        (self.hooks["#{time}_#{name}".to_sym] ||= []) << action
      end # }}}

      # @private
      def perform_hook(record, time, name) # {{{
        Array(self.hooks["#{time}_#{name}".to_sym]).each do |hook|
          if hook.is_a? Symbol
            record.send(hook)
          else
            hook.call(record)
          end
        end
      end # }}}

      # Perform “after” hooks on a resource
      # @private
      def perform_after_hooks(resource, *hooks) # {{{
        hooks.each do |hook|
          perform_hook(resource, :after, hook)
        end
      end # }}}

      # Perform “before” hooks on a resource
      # @private
      def perform_before_hooks(resource, *hooks) # {{{
        hooks.each do |hook|
          perform_hook(resource, :before, hook)
        end
      end # }}}
    end
  end
end
