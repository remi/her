module Her
  module Model
    module Associations
      class BelongsToAssociation < Association
        def self.attach(klass, name, attrs)
          attrs = {
            :class_name => name.to_s.classify,
            :name => name,
            :data_key => name,
            :foreign_key => "#{name}_id",
            :path => "/#{name.to_s.pluralize}/:id"
          }.merge(attrs)
          klass.associations[:belongs_to] << attrs

          klass.instance_eval do
            define_method(name) do
              cached_name = :"@_her_association_#{name}"

              cached_data = (instance_variable_defined?(cached_name) && instance_variable_get(cached_name))
              cached_data || instance_variable_set(cached_name, Her::Model::Associations::BelongsToAssociation.new(self, attrs))
            end
          end
        end

        def build(attributes = {})
          @klass.new(attributes)
        end

        def create(attributes = {})
          resource = build(attributes)
          @parent.attributes[@name] = resource if resource.save
          resource
        end

        def fetch
          foreign_key_value = @parent.attributes[@opts[:foreign_key].to_sym]
          return nil if (@parent.attributes.include?(@name) && @parent.attributes[@name].nil? && @query_attrs.empty?) || foreign_key_value.blank?

          if @parent.attributes[@name].blank? || @query_attrs.any?
            path = begin
              @klass.build_request_path(@parent.attributes.merge(@query_attrs.merge(@klass.primary_key => foreign_key_value)))
            rescue Her::Errors::PathError
              return nil
            end

            @klass.get_resource("#{path}", @query_attrs)
          else
            @parent.attributes[@name]
          end
        end
      end
    end
  end
end
