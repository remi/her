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
          return nil if @parent.attributes.include?(@name) && @parent.attributes[@name].nil? && @method_attrs.empty?

          if @parent.attributes[@name].blank? || @method_attrs.any?
            path = begin
              @parent.request_path(@method_attrs)
            rescue Her::Errors::PathError
              return nil
            end

            @parent.attributes[@name] = @klass.get_resource("#{path}#{@opts[:path]}", @method_attrs)
          end

          @parent.attributes[@name]
        end
      end
    end
  end
end
