module Her
  module Model
    module Associations
      class HasOneAssociation < Association
        def build(attributes = {})
          # TODO
        end

        def create(attributes = {})
          # TODO
        end

        def fetch
          return nil if @parent.attributes.include?(@name) && @parent.attributes[@name].nil? && @query_attrs.empty?

          if @parent.attributes[@name].blank? || @query_attrs.any?
            path = begin
              @parent.request_path(@query_attrs)
            rescue Her::Errors::PathError
              return nil
            end

            @parent.attributes[@name] = @klass.get_resource("#{path}#{@opts[:path]}", @query_attrs)
          end

          @parent.attributes[@name]
        end
      end
    end
  end
end
