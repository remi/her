module Her
  module Model
    module Associations
      class HasManyAssociation < Association
        def build(attributes = {})
          @klass.new(attributes.merge(:"#{@parent.singularized_resource_name}_id" => @parent.id))
        end

        def create(attributes = {})
          resource = build(attributes)

          if resource.save
            @parent.attributes[@name] ||= Her::Collection.new
            @parent.attributes[@name] << resource
          end

          resource
        end

        def fetch
          return Her::Collection.new if @parent.attributes.include?(@name) && @parent.attributes[@name].empty? && @query_attrs.empty?

          output = if @parent.attributes[@name].blank? || @query_attrs.any?
            path = begin
              @parent.request_path(@query_attrs)
            rescue Her::Errors::PathError
              return nil
            end

            @klass.get_collection("#{path}#{@opts[:path]}", @query_attrs)
          else
            @parent.attributes[@name]
          end

          inverse_of = @opts[:inverse_of] || @parent.singularized_resource_name
          output.each { |entry| entry.send("#{inverse_of}=", @parent) }

          output
        end
      end
    end
  end
end
