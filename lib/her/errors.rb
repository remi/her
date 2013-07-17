module Her
  module Errors
    class PathError < StandardError
      attr_reader :missing_parameter

      def initialize(message, missing_parameter=nil)
        super(message)
        @missing_parameter = missing_parameter
      end
    end

    class AssociationUnknownError < StandardError
    end

    class ParseError < StandardError
    end

    class ResourceInvalid < StandardError
      attr_reader :resource
      def initialize(resource)
        @resource = resource
        errors = @resource.response_errors.join(", ")
        super("Remote validation failed: #{errors}")
      end
    end
  end
end
