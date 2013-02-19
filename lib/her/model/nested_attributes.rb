module Her
  module Model
    module NestedAttributes
      module ClassMethods
        def accepts_nested_attributes_for(*relationship_names)
          relationship_names.each do |relationship_name|
            type = nil
            [:belongs_to, :has_one, :has_many].each do |relation_type|
              if !relationships[relation_type].nil? && relationships[relation_type].any? { |relation| relation[:name] == relationship_name }
                type = relation_type
              end
            end
            if type.nil?
              raise(RelationshipUnknownError.new("Unknown relationship name :#{relationship_name}"))
            end
            class_eval <<-eoruby, __FILE__, __LINE__ + 1
              if method_defined?(:#{relationship_name}_attributes=)
                remove_method(:#{relationship_name}_attributes=)
              end
              def #{relationship_name}_attributes=(attributes)
                assign_nested_attributes_for_#{type}_relationship(:#{relationship_name}, attributes)
              end
            eoruby
          end
        end
      end

      def assign_nested_attributes_for_belongs_to_relationship(relationship_name, attributes)
        assign_nested_attributes_for_simple_relationship(:belongs_to, relationship_name, attributes)
      end

      def assign_nested_attributes_for_has_one_relationship(relationship_name, attributes)
        assign_nested_attributes_for_simple_relationship(:has_one, relationship_name, attributes)
      end

      def assign_nested_attributes_for_has_many_relationship(relationship_name, attributes)
        relationship = self.class.relationships[:has_many].find { |relation| relation[:name] == relationship_name }
        klass = self.class.nearby_class(relationship[:class_name])
        self.send("#{relationship[:name]}=", Her::Model::ORM.initialize_collection(klass, :data => attributes))
      end

      private
      def assign_nested_attributes_for_simple_relationship(relationship_type, relationship_name, attributes)
        relationship = self.class.relationships[relationship_type].find { |relation| relation[:name] == relationship_name }
        if has_data?(relationship[:name])
          self.send("#{relationship[:name]}").assign_data(attributes)
        else
          klass = self.class.nearby_class(relationship[:class_name])
          instance = klass.new(klass.parse(attributes))
          self.send("#{relationship[:name]}=", instance)
        end
      end
    end
  end
end
