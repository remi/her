module Her
  module Model
    module Associations
      class BelongsToAssociation < Association

        # @private
        def self.attach(klass, name, opts)
          opts = {
            :class_name => name.to_s.classify,
            :name => name,
            :data_key => name,
            :default => nil,
            :foreign_key => "#{name}_id",
            :path => "/#{name.to_s.pluralize}/:id"
          }.merge(opts)
          klass.associations[:belongs_to] << opts

          klass.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{name}
              cached_name = :"@_her_association_#{name}"

              cached_data = (instance_variable_defined?(cached_name) && instance_variable_get(cached_name))
              cached_data || instance_variable_set(cached_name, Her::Model::Associations::BelongsToAssociation.proxy(self, #{opts.inspect}))
            end
          RUBY
        end

        # @private
        def self.parse(*args)
          parse_single(*args)
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
          @klass.build(attributes)
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
          data_key_value = @parent.attributes[@opts[:data_key].to_sym]
          return @opts[:default].try(:dup) if (@parent.attributes.include?(@name) && @parent.attributes[@name].nil? && @params.empty?) || (foreign_key_value.blank? && data_key_value.blank?)

          return @cached_result unless @params.any? || @cached_result.nil?
          return @parent.attributes[@name] unless @params.any? || @parent.attributes[@name].blank?

          path_params = @parent.attributes.merge(@params.merge(@klass.primary_key => foreign_key_value))
          path = build_association_path lambda { @klass.build_request_path(path_params) }
          @klass.get_resource(path, @params).tap do |result|
            @cached_result = result if @params.blank?
          end
        end

        # @private
        def assign_nested_attributes(attributes)
          assign_single_nested_attributes(attributes)
        end
      end
    end
  end
end
