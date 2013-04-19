module Her
  module Model
    module Associations
      class HasOneAssociation < Association
        def build(attributes = {})
          @klass.new(attributes.merge(:"#{@parent.singularized_resource_name}_id" => @parent.id))
        end

        def create(attributes = {})
          resource = build(attributes)
          @parent.attributes[@name] = resource if resource.save
          resource
        end

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
