module Her
  module Model
    module Associations
      class AssociationProxy < (ActiveSupport.const_defined?('ProxyObject') ? ActiveSupport::ProxyObject : ActiveSupport::BasicObject)

        # @private
        def self.install_proxy_methods(target_name, *names)
          names.each do |name|
            module_eval <<-RUBY, __FILE__, __LINE__ + 1
              def #{name}(*args, &block)
                #{target_name}.send(#{name.inspect}, *args, &block)
              end
            RUBY
          end
        end

        install_proxy_methods :association,
          :build, :create, :where, :find, :all, :assign_nested_attributes, :reload

        # @private
        def initialize(association)
          @_her_association = association
        end

        def association
          @_her_association
        end

        # @private
        def method_missing(name, *args, &block)
          if :object_id == name # avoid redefining object_id
            return association.fetch.object_id
          end

          # create a proxy to the fetched object's method
          AssociationProxy.install_proxy_methods 'association.fetch', name

          # resend message to fetched object
          __send__(name, *args, &block)
        end

      end
    end
  end
end
