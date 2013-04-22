module Her
  module Model
    module Associations
      class HasOneAssociation < Association
        # @private
        def self.attach(klass, name, attrs)
          attrs = {
            :class_name => name.to_s.classify,
            :name => name,
            :data_key => name,
            :path => "/#{name}"
          }.merge(attrs)
          klass.associations[:has_one] << attrs

          klass.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{name}
              cached_name = :"@_her_association_#{name}"

              cached_data = (instance_variable_defined?(cached_name) && instance_variable_get(cached_name))
              cached_data || instance_variable_set(cached_name, Her::Model::Associations::HasOneAssociation.new(self, #{attrs.inspect}))
            end
          RUBY
        end

        def build(attributes = {})
          @klass.new(attributes.merge(:"#{@parent.singularized_resource_name}_id" => @parent.id))
        end

        def create(attributes = {})
          resource = build(attributes)
          @parent.attributes[@name] = resource if resource.save
          resource
        end

        # @private
        def fetch
          return nil if @parent.attributes.include?(@name) && @parent.attributes[@name].nil? && @query_attrs.empty?

          if @parent.attributes[@name].blank? || @query_attrs.any?
            path = begin
              @parent.request_path(@query_attrs)
            rescue Her::Errors::PathError
              return nil
            end

            @klass.get_resource("#{path}#{@opts[:path]}", @query_attrs)
          else
            @parent.attributes[@name]
          end
        end
      end
    end
  end
end
