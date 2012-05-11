require "her/middleware/first_level_parse_json"
require "her/middleware/second_level_parse_json"

module Her
  module Middleware
    DefaultParseJSON = FirstLevelParseJSON
  end
end
