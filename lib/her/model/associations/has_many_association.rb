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

          inverse_of = @opts[:inverse_of] || @parent.class.name.split('::').last.tableize.singularize
          output.each { |entry| entry.send("#{inverse_of}=", @parent) }

          output
        end
      end
    end
  end
end
