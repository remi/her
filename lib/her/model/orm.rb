module Her
  module Model
    # This module adds ORM-like capabilities to the model
    module ORM
      extend ActiveSupport::Concern

      # Return `true` if a resource was not saved yet
      def new?
        id.nil?
      end

      # Return `true` if a resource is not `#new?`
      def persisted?
        !new?
      end

      # Return whether the object has been destroyed
      def destroyed?
        @destroyed == true
      end

      # Save a resource and return `false` if the response is not a successful one or
      # if there are errors in the resource. Otherwise, return the newly updated resource
      #
      # @example Save a resource after fetching it
      #   @user = User.find(1)
      #   # Fetched via GET "/users/1"
      #   @user.fullname = "Tobias Fünke"
      #   @user.save
      #   # Called via PUT "/users/1"
      #
      # @example Save a new resource by creating it
      #   @user = User.new({ :fullname => "Tobias Fünke" })
      #   @user.save
      #   # Called via POST "/users"
      def save
        callback = new? ? :create : :update
        method = self.class.method_for(callback)

        run_callbacks callback do
          run_callbacks :save do
            params = to_params
            self.class.request(to_params.merge(:_method => method, :_path => request_path)) do |parsed_data, response|
              assign_attributes(self.class.parse(parsed_data[:data])) if parsed_data[:data].any?
              self.metadata = parsed_data[:metadata]
              self.response_errors = parsed_data[:errors]
              self.changed_attributes.clear if self.changed_attributes.present?

              return false if !response.success? || self.response_errors.any?
            end
          end
        end

        self
      end

      # Destroy a resource
      #
      # @example
      #   @user = User.find(1)
      #   @user.destroy
      #   # Called via DELETE "/users/1"
      def destroy
        method = self.class.method_for(:destroy)
        run_callbacks :destroy do
          self.class.request(:_method => method, :_path => request_path) do |parsed_data, response|
            assign_attributes(self.class.parse(parsed_data[:data])) if parsed_data[:data].any?
            self.metadata = parsed_data[:metadata]
            self.response_errors = parsed_data[:errors]
            @destroyed = true
          end
        end
        self
      end

      module ClassMethods
        # Fetch specific resource(s) by their ID
        #
        # @example
        #   @user = User.find(1)
        #   # Fetched via GET "/users/1"
        #
        # @example
        #   @users = User.find([1, 2])
        #   # Fetched via GET "/users/1" and GET "/users/2"
        def find(*ids)
          params = ids.last.is_a?(Hash) ? ids.pop : {}
          results = ids.flatten.compact.uniq.map do |id|
            resource = nil
            request(params.merge(:_method => method_for(:find), :_path => build_request_path(params.merge(primary_key => id)))) do |parsed_data, response|
              if response.success?
                resource = new(parse(parsed_data[:data]).merge :_metadata => parsed_data[:metadata], :_errors => parsed_data[:errors])
                resource.run_callbacks :find
              else
                return nil
              end
            end
            resource
          end

          if ids.length > 1 || ids.first.kind_of?(Array)
            results
          else
            results.first
          end
        end

        # Create a new chainable scope
        #
        # @example
        #   class User
        #     include Her::Model
        #
        #     scope :admins, lambda { where(:admin => 1) }
        #     scope :page, lambda { |page| where(:page => page) }
        #   enc
        #
        #   User.admins # Called via GET "/users?admin=1"
        #   User.page(2).all # Called via GET "/users?page=2"
        def scope(name, code)
          define_singleton_method(name) { |*args| instance_exec(*args, &code) }

          Relation.instance_eval do
            define_method(name) { |*args| instance_exec(*args, &code) }
          end
        end

        # @private
        def scoped
          Relation.new(self)
        end

        # Delegate the following methods to `scoped`
        [:all, :where, :create, :build, :first_or_create, :first_or_initialize].each do |method|
          define_method(method) { |*attrs| scoped.send(method, *attrs) }
        end

        # Save an existing resource and return it
        #
        # @example
        #   @user = User.save_existing(1, { :fullname => "Tobias Fünke" })
        #   # Called via PUT "/users/1"
        def save_existing(id, params)
          resource = new(params.merge(primary_key => id))
          resource.save
          resource
        end

        # Destroy an existing resource
        #
        # @example
        #   User.destroy_existing(1)
        #   # Called via DELETE "/users/1"
        def destroy_existing(id, params={})
          request(params.merge(:_method => method_for(:destroy), :_path => build_request_path(params.merge(primary_key => id)))) do |parsed_data, response|
            new(parse(parsed_data[:data]).merge(:_destroyed => true))
          end
        end

        # Return or change the HTTP method used to create or update records
        #
        # @param [Symbol, String] action The behavior in question (`:create` or `:update`)
        # @param [Symbol, String] method The HTTP method to use (`'PUT'`, `:post`, etc.)
        def method_for(action = nil, method = nil)
          @method_for ||= (superclass.respond_to?(:method_for) ? superclass.method_for : {})
          return @method_for if action.nil?

          action = action.to_sym.downcase

          return @method_for[action] if method.nil?
          @method_for[action] = method.to_sym.downcase
        end
      end
    end
  end
end
