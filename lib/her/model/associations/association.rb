module Her
  module Model
    module Associations
      class Association
        def initialize(parent, opts = {}, *method_attrs)
          @parent = parent
          @opts = opts
          @method_attrs = method_attrs[0] || {}

          @klass = @parent.class.her_nearby_class(@opts[:class_name])
          @name = @opts[:name]
        end

        def class
          fetch.class
        end

        def nil?
          fetch.nil?
        end

        def kind_of?(thing)
          fetch.kind_of?(thing)
        end

        def method_missing(method, *args, &blk)
          fetch.send(method, *args)
        end
      end
    end
  end
end
