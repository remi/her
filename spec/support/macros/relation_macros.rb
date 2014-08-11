module Her
  module Testing
    module Macros
      module RelationMacros
        # Create a class and automatically inherit Her::Model::Relation
        def spawn_relation(klass, &block)
          if klass =~ /::/
            base, submodel = klass.split(/::/).map{ |s| s.to_sym }
            Object.const_set(base, Module.new) unless Object.const_defined?(base)
            Object.const_get(base).module_eval do
              remove_const submodel if constants.map(&:to_sym).include?(submodel)
              submodel = const_set(submodel, Class.new(Her::Model::Relation))
              submodel.class_eval(&block) if block_given?
            end

            @spawned_classes << base
          else
            Object.instance_eval { remove_const klass } if Object.const_defined?(klass)
            Object.const_set(klass, Class.new(Her::Model::Relation))
            Object.const_get(klass).class_eval(&block) if block_given?

            @spawned_classes << klass.to_sym
          end
        end
      end
    end
  end
end
