module Her
  module Model
    # This module handles resource data parsing at the model level (after the parsing middleware)
    module Parse
      extend ActiveSupport::Concern

      # Convert into a hash of request parameters, based on `include_root_in_json`.
      #
      # @example
      #   @user.to_params
      #   # => { :id => 1, :name => 'John Smith' }
      def to_params
        self.class.include_root_in_json? ? { self.class.included_root_element => attributes.dup } : attributes.dup
      end

      module ClassMethods
        # Parse data before assigning it to a resource, based on `parse_root_in_json`.
        #
        # @param [Hash] data
        def parse(data)
          parse_root_in_json? ? data[parsed_root_element] : data
        end

        # Return or change the value of `include_root_in_json`
        #
        # @example
        #   class User
        #     include Her::Model
        #     include_root_in_json true
        #   end
        def include_root_in_json(value=nil)
          return @include_root_in_json if value.nil?
          @include_root_in_json = value
        end

        # Return or change the value of `parse_root_in`
        #
        # @example
        #   class User
        #     include Her::Model
        #     parse_root_in_json true
        #   end
        def parse_root_in_json(value=nil)
          return @parse_root_in_json if value.nil?
          @parse_root_in_json = value
        end

        # Return or change the value of `root_element`
        #
        # @example
        #   class User
        #     include Her::Model
        #     parse_root_in_json true
        #     root_element :huh
        #   end
        #
        #   user = User.find(1) # { :huh => { :id => 1, :name => "Tobias" } }
        #   user.name # => "Tobias"
        def root_element(value=nil)
          return @root_element if value.nil?
          @root_element = value
        end

        # @private
        def parse_root_in_json?
          @parse_root_in_json
        end

        # @private
        def include_root_in_json?
          @include_root_in_json
        end

        # @private
        def included_root_element
          include_root_in_json == true ? root_element.to_sym : include_root_in_json
        end

        # @private
        def parsed_root_element
          parse_root_in_json == true ? root_element.to_sym : parse_root_in_json
        end
      end
    end
  end
end
