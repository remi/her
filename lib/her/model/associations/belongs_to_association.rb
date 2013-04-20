module Her
  module Model
    module Associations
      class BelongsToAssociation < Association
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
