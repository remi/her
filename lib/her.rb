require "her/version"
require "multi_json"
require "faraday"
require "active_support"
require "active_support/inflector"

module Her
  autoload :Model,       "her/model"
  autoload :API,         "her/api"
  autoload :Middleware,  "her/middleware"
  autoload :Errors,      "her/errors"
end
