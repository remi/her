module Her
  module Errors
    class PathError < StandardError; end;
    class AssociationUnknownError < StandardError; end;
    class ParseError < StandardError; end;
  end
end
