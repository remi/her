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
  end
end
