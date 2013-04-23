module Her
  module Model
    module NestedAttributes
      extend ActiveSupport::Concern

      module ClassMethods
        # Allow nested attributes for an association
        def accepts_nested_attributes_for(*association_names)
          association_names.each do |association_name|
            type = nil
            [:belongs_to, :has_one, :has_many].each do |association_type|
              if !associations[association_type].nil? && associations[association_type].any? { |association| association[:name] == association_name }
                type = association_type
              end
            end

            raise(AssociationUnknownError.new("Unknown association name :#{association_name}")) if type.nil?

            class_eval <<-RUBY, __FILE__, __LINE__ + 1
              if method_defined?(:#{association_name}_attributes=)
                remove_method(:#{association_name}_attributes=)
              end
              def #{association_name}_attributes=(attributes)
                assign_nested_attributes_for_#{type}_association(:#{association_name}, attributes)
              end
            RUBY
          end
        end
      end

      # @private
      def assign_nested_attributes_for_belongs_to_association(association_name, attributes)
        assign_nested_attributes_for_simple_association(:belongs_to, association_name, attributes)
      end

      # @private
      def assign_nested_attributes_for_has_one_association(association_name, attributes)
        assign_nested_attributes_for_simple_association(:has_one, association_name, attributes)
      end

      # @private
      def assign_nested_attributes_for_has_many_association(association_name, attributes)
        association = self.class.associations[:has_many].find { |association| association[:name] == association_name }
        klass = self.class.her_nearby_class(association[:class_name])
        self.send("#{association[:name]}=", Her::Model::Attributes.initialize_collection(klass, :data => attributes))
      end

      private
      def assign_nested_attributes_for_simple_association(association_type, association_name, attributes)
        association = self.class.associations[association_type].find { |association| association[:name] == association_name }
        if has_attribute?(association[:name])
          self.send(association[:name]).assign_attributes(attributes)
        else
          klass = self.class.her_nearby_class(association[:class_name])
          instance = klass.new(klass.parse(attributes))
          self.send("#{association[:name]}=", instance)
        end
      end
    end
  end
end
