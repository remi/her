module Her
  module Model
    module Associations
      class HasOneAssociation < Association
        # @private
        def self.attach(klass, name, attrs)
          attrs = {
            :class_name => name.to_s.classify,
            :name => name,
            :data_key => name,
            :path => "/#{name}"
          }.merge(attrs)
          klass.associations[:has_one] << attrs

          klass.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{name}
              cached_name = :"@_her_association_#{name}"

              cached_data = (instance_variable_defined?(cached_name) && instance_variable_get(cached_name))
              cached_data || instance_variable_set(cached_name, Her::Model::Associations::HasOneAssociation.new(self, #{attrs.inspect}))
            end
          RUBY
        end

        # @private
        def self.parse(association, klass, data)
          data_key = association[:data_key]
          return {} unless data[data_key]

          klass = klass.her_nearby_class(association[:class_name])
          { association[:name] => klass.new(data[data_key]) }
        end

        # Initialize a new object with a foreign key to the parent
        #
        # @example
        #   class User
        #     include Her::Model
        #     has_one :role
        #   end
        #
        #   class Role
        #     include Her::Model
        #   end
        #
        #   user = User.find(1)
        #   new_role = user.role.build(:title => "moderator")
        #   new_role # => #<Role user_id=1 title="moderator">
        def build(attributes = {})
          @klass.new(attributes.merge(:"#{@parent.singularized_resource_name}_id" => @parent.id))
        end

        # Create a new object, save it and associate it to the parent
        #
        # @example
        #   class User
        #     include Her::Model
        #     has_one :role
        #   end
        #
        #   class Role
        #     include Her::Model
        #   end
        #
        #   user = User.find(1)
        #   user.role.create(:title => "moderator")
        #   user.role # => #<Role id=2 user_id=1 title="moderator">
        def create(attributes = {})
          resource = build(attributes)
          @parent.attributes[@name] = resource if resource.save
          resource
        end

        # @private
        def fetch
          return nil if @parent.attributes.include?(@name) && @parent.attributes[@name].nil? && @query_attrs.empty?

          if @parent.attributes[@name].blank? || @query_attrs.any?
            path = begin
              @parent.request_path(@query_attrs)
            rescue Her::Errors::PathError
              return nil
            end

            @klass.get_resource("#{path}#{@opts[:path]}", @query_attrs)
          else
            @parent.attributes[@name]
          end
        end
      end
    end
  end
end
