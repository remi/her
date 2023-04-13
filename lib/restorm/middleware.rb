require "restorm/middleware/parse_json"
require "restorm/middleware/first_level_parse_json"
require "restorm/middleware/second_level_parse_json"
require "restorm/middleware/accept_json"

module Restorm
  module Middleware
    DefaultParseJSON = FirstLevelParseJSON

    autoload :JsonApiParser, 'restorm/middleware/json_api_parser'
  end
end
