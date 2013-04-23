module Her
  module Model
    module Associations
      class BelongsToAssociation < Association
        # @private
        def self.attach(klass, name, attrs)
          attrs = {
            :class_name => name.to_s.classify,
            :name => name,
            :data_key => name,
            :foreign_key => "#{name}_id",
            :path => "/#{name.to_s.pluralize}/:id"
          }.merge(attrs)
          klass.associations[:belongs_to] << attrs

          klass.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{name}
              cached_name = :"@_her_association_#{name}"

              cached_data = (instance_variable_defined?(cached_name) && instance_variable_get(cached_name))
              cached_data || instance_variable_set(cached_name, Her::Model::Associations::BelongsToAssociation.new(self, #{attrs.inspect}))
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

        # Initialize a new object
        #
        # @example
        #   class User
        #     include Her::Model
        #     belongs_to :organization
        #   end
        #
        #   class Organization
        #     include Her::Model
        #   end
        #
        #   user = User.find(1)
        #   new_organization = user.organization.build(:name => "Foo Inc.")
        #   new_organization # => #<Organization name="Foo Inc.">
        def build(attributes = {})
          @klass.new(attributes)
        end

        # Create a new object, save it and associate it to the parent
        #
        # @example
        #   class User
        #     include Her::Model
        #     belongs_to :organization
        #   end
        #
        #   class Organization
        #     include Her::Model
        #   end
        #
        #   user = User.find(1)
        #   user.organization.create(:name => "Foo Inc.")
        #   user.organization # => #<Organization id=2 name="Foo Inc.">
        def create(attributes = {})
          resource = build(attributes)
          @parent.attributes[@name] = resource if resource.save
          resource
        end

        # @private
        def fetch
          foreign_key_value = @parent.attributes[@opts[:foreign_key].to_sym]
          return nil if (@parent.attributes.include?(@name) && @parent.attributes[@name].nil? && @query_attrs.empty?) || (@parent.persisted? && foreign_key_value.blank?)

          if @parent.attributes[@name].blank? || @query_attrs.any?
            path = begin
              @klass.build_request_path(@parent.attributes.merge(@query_attrs.merge(@klass.primary_key => foreign_key_value)))
            rescue Her::Errors::PathError
              return nil
            end

            @klass.get_resource(path, @query_attrs)
          else
            @parent.attributes[@name]
          end
        end

        # @private
        def assign_nested_attributes(attributes)
          if @parent.attributes[@name].blank?
            @parent.attributes[@name] = @klass.new(@klass.parse(attributes))
          else
            @parent.attributes[@name].assign_attributes(attributes)
          end
        end
      end
    end
  end
end
