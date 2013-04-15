module Her
  module Model
    module Associations
      class BelongsToAssociation < Association
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
              @klass.build_request_path(@parent.attributes.merge(@method_attrs.merge(@klass.primary_key => @parent.attributes[@opts[:foreign_key].to_sym])))
            rescue Her::Errors::PathError
              return nil
            end

            @parent.attributes[@name] = @klass.get_resource("#{path}", @method_attrs)
          end

          @parent.attributes[@name]
        end
      end
    end
  end
end
