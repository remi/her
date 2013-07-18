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
        def self.parse_single(association, klass, data)
          data_key = association[:data_key]
          return {} unless data[data_key]

          klass = klass.her_nearby_class(association[:class_name])
          { association[:name] => klass.new(data[data_key]) }
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
          return @opts[:default].try(:dup) if @parent.attributes.include?(@name) && @parent.attributes[@name].empty? && @params.empty?

          if @parent.attributes[@name].blank? || @params.any?
            path = build_association_path lambda { "#{@parent.request_path(@params)}#{@opts[:path]}" }
            @klass.get(path, @params)
          else
            @parent.attributes[@name]
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
          self.clone.tap { |a| a.params = a.params.merge(params) }
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
          @klass.get(path, @params)
        end

        # @private
        def nil?
          fetch.nil?
        end

        # @private
        def empty?
          fetch.empty?
        end

        # @private
        def kind_of?(thing)
          fetch.kind_of?(thing)
        end

        # @private
        def ==(other)
          fetch.eql?(other)
        end
        alias eql? ==

        # ruby 1.8.7 compatibility
        # @private
        def id
          fetch.id
        end

        # @private
        def method_missing(method, *args, &blk)
          fetch.send(method, *args, &blk)
        end
      end
    end
  end
end
