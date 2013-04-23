module Her
  module Model
    module Associations
      class HasManyAssociation < Association
        # @private
        def self.attach(klass, name, attrs)
          attrs = {
            :class_name     => name.to_s.classify,
            :name           => name,
            :data_key       => name,
            :path           => "/#{name}",
            :inverse_of => nil
          }.merge(attrs)
          klass.associations[:has_many] << attrs

          klass.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{name}
              cached_name = :"@_her_association_#{name}"

              cached_data = (instance_variable_defined?(cached_name) && instance_variable_get(cached_name))
              cached_data || instance_variable_set(cached_name, Her::Model::Associations::HasManyAssociation.new(self, #{attrs.inspect}))
            end
          RUBY
        end

        # @private
        def self.parse(association, klass, data)
          data_key = association[:data_key]
          return {} unless data[data_key]

          klass = klass.her_nearby_class(association[:class_name])
          { association[:name] => Her::Model::Attributes.initialize_collection(klass, :data => data[data_key]) }
        end

        # Initialize a new object with a foreign key to the parent
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
        #   new_comment = user.comments.build(:body => "Hello!")
        #   new_comment # => #<Comment user_id=1 body="Hello!">
        def build(attributes = {})
          @klass.new(attributes.merge(:"#{@parent.singularized_resource_name}_id" => @parent.id))
        end

        # Create a new object, save it and add it to the associated collection
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
        #   user.comments.create(:body => "Hello!")
        #   user.comments # => [#<Comment id=2 user_id=1 body="Hello!">]
        def create(attributes = {})
          resource = build(attributes)

          if resource.save
            @parent.attributes[@name] ||= Her::Collection.new
            @parent.attributes[@name] << resource
          end

          resource
        end

        # @private
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

          inverse_of = @opts[:inverse_of] || @parent.singularized_resource_name
          output.each { |entry| entry.send("#{inverse_of}=", @parent) }

          output
        end

        # @private
        def assign_nested_attributes(attributes)
          @parent.attributes[@name] = Her::Model::Attributes.initialize_collection(@klass, :data => attributes)
        end
      end
    end
  end
end
