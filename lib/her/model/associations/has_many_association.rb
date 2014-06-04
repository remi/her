module Her
  module Model
    module Associations
      class HasManyAssociation < Association

        # @private
        def self.attach(klass, name, opts)
          opts = {
            :class_name     => name.to_s.classify,
            :name           => name,
            :data_key       => name,
            :default        => Her::Collection.new,
            :path           => "/#{name}",
            :inverse_of => nil
          }.merge(opts)
          klass.associations[:has_many] << opts

          klass.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{name}
              cached_name = :"@_her_association_#{name}"

              cached_data = (instance_variable_defined?(cached_name) && instance_variable_get(cached_name))
              cached_data || instance_variable_set(cached_name, Her::Model::Associations::HasManyAssociation.proxy(self, #{opts.inspect}))
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
        # TODO: This only merges the id of the parents, handle the case
        #       where this is more deeply nested
        def build(attributes = {})
          @klass.build(attributes.merge(:"#{@parent.singularized_resource_name}_id" => @parent.id))
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
          super.tap do |o|
            inverse_of = @opts[:inverse_of] || @parent.singularized_resource_name
            o.each { |entry| entry.send("#{inverse_of}=", @parent) }
          end
        end

        # @private
        def assign_nested_attributes(attributes)
          data = attributes.is_a?(Hash) ? attributes.values : attributes
          @parent.attributes[@name] = Her::Model::Attributes.initialize_collection(@klass, :data => data)
        end
      end
    end
  end
end
