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
        if self.class.include_root_in_json
          { (self.class.include_root_in_json == true ? self.class.root_element : self.class.include_root_in_json) => attributes.dup }
        else
          attributes.dup
        end
      end

      module ClassMethods
        # Parse data before assigning it to a resource, based on `parse_root_in_json`.
        #
        # @param [Hash] data
        def parse(data)
          if parse_root_in_json
            parse_root_in_json == true ? data[root_element.to_sym] : data[parse_root_in_json]
          else
            data
          end
        end

        # Return or change the value of `include_root_in_json`
        def include_root_in_json(value=nil)
          return @include_root_in_json if value.nil?
          @include_root_in_json = value
        end

        # Return or change the value of `parse_root_in`
        def parse_root_in_json(value=nil)
          return @parse_root_in_json if value.nil?
          @parse_root_in_json = value
        end
      end
    end
  end
end
