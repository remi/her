module Her
  module Model
    module Associations
      class Association
        attr_accessor :query_attrs

        def initialize(parent, opts = {})
          @parent = parent
          @opts = opts
          @query_attrs = {}

          @klass = @parent.class.her_nearby_class(@opts[:class_name])
          @name = @opts[:name]
        end

        def where(attrs = {})
          return self if attrs.blank?
          self.clone.tap { |a| a.query_attrs = a.query_attrs.merge(attrs) }
        end
        alias :all :where

        def nil?
          fetch.nil?
        end

        def kind_of?(thing)
          fetch.kind_of?(thing)
        end

        def method_missing(method, *args, &blk)
          fetch.send(method, *args, &blk)
        end
      end
    end
  end
end
