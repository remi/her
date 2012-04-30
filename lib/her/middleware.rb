module Her
  module Middleware
    autoload :FirstLevelParseJSON,  "her/middleware/first_level_parse_json"
    autoload :SecondLevelParseJSON, "her/middleware/second_level_parse_json"

    DefaultParseJSON = FirstLevelParseJSON
  end
end
