module Her
  module Model
    module Associations
      class HasManyAssociation < Association
        def build(attributes = {})
          # TODO
        end

        def create(attributes = {})
          # TODO
        end

        def fetch
          return Her::Collection.new if @parent.attributes.include?(@name) && @parent.attributes[@name].empty? && @method_attrs.empty?

          if @parent.attributes[@name].blank? || @method_attrs.any?
            path = begin
              @parent.request_path(@method_attrs)
            rescue Her::Errors::PathError
              return nil
            end

            @parent.attributes[@name] = @klass.get_collection("#{path}#{@opts[:path]}", @method_attrs)
          end

          inverse_of = @opts[:inverse_of] || @parent.class.name.split('::').last.tableize.singularize
          @parent.attributes[@name].each { |entry| entry.send("#{inverse_of}=", @parent) }

          @parent.attributes[@name]
        end
      end
    end
  end
end
