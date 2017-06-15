module Her
  module Model
    module Associations
      class Association
        # @private
        attr_accessor :params

        # @private
        def initialize(parent, opts = {})
          @parent = parent
          @opts = opts
          @params = {}

          @klass = @parent.class.her_nearby_class(@opts[:class_name])
          @name = @opts[:name]
        end

        # @private
        def self.proxy(parent, opts = {})
          AssociationProxy.new new(parent, opts)
        end

        # @private
        def self.parse_single(association, klass, data)
          data_key = association[:data_key]
          return {} unless data[data_key]

          klass = klass.her_nearby_class(association[:class_name])
          if data[data_key].kind_of?(klass)
            { association[:name] => data[data_key] }
          else
            { association[:name] => klass.new(klass.parse(data[data_key])) }
          end
        end

        # @private
        def assign_single_nested_attributes(attributes)
          if @parent.attributes[@name].blank?
            @parent.attributes[@name] = @klass.new(@klass.parse(attributes))
          else
            @parent.attributes[@name].assign_attributes(attributes)
          end
        end

        # @private
        def fetch(opts = {})
          attribute_value = @parent.attributes[@name]
          return @opts[:default].try(:dup) if @parent.attributes.include?(@name) && (attribute_value.nil? || !attribute_value.nil? && attribute_value.empty?) && @params.empty?

          return @cached_result unless @params.any? || @cached_result.nil?
          return @parent.attributes[@name] unless @params.any? || @parent.attributes[@name].blank?
          return @opts[:default].try(:dup) if @parent.new?

          path = build_association_path lambda { "#{@parent.request_path(@params)}#{@opts[:path]}" }
          @klass.get(path, @params).tap do |result|
            @cached_result = result unless @params.any?
          end
        end

        # @private
        def build_association_path(code)
          begin
            instance_exec(&code)
          rescue Her::Errors::PathError
            return nil
          end
        end

        # @private
        def reset
          @params = {}
          @cached_result = nil
          @parent.attributes.delete(@name)
        end

        # Add query parameters to the HTTP request performed to fetch the data
        #
        # @example
        #   class User
        #     include Her::Model
        #     has_many :comments
        #   end
        #
        #   user = User.find(1)
        #   user.comments.where(:approved => 1) # Fetched via GET "/users/1/comments?approved=1
        def where(params = {})
          return self if params.blank? && @parent.attributes[@name].blank?
          AssociationProxy.new self.clone.tap { |a| a.params = a.params.merge(params) }
        end
        alias all where

        # Fetches the data specified by id
        #
        # @example
        #   class User
        #     include Her::Model
        #     has_many :comments
        #   end
        #
        #   user = User.find(1)
        #   user.comments.find(3) # Fetched via GET "/users/1/comments/3
        def find(id)
          return nil if id.blank?
          path = build_association_path lambda { "#{@parent.request_path(@params)}#{@opts[:path]}/#{id}" }
          @klass.get_resource(path, @params)
        end

        # Refetches the association and puts the proxy back in its initial state,
        # which is unloaded. Cached associations are cleared.
        #
        # @example
        #   class User
        #     include Her::Model
        #     has_many :comments
        #   end
        #
        #   class Comment
        #     include Her::Model
        #   end
        #
        #   user = User.find(1)
        #   user.comments = [#<Comment(comments/2) id=2 body="Hello!">]
        #   user.comments.first.id = "Oops"
        #   user.comments.reload # => [#<Comment(comments/2) id=2 body="Hello!">]
        #   # Fetched again via GET "/users/1/comments"
        def reload
          reset
          fetch
        end

      end
    end
  end
end
