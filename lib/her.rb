require "her/version"
require "json"
require "faraday"
require "active_support"
require "active_support/inflector"

module Her
  autoload :Model, "her/model"
  autoload :API,   "her/api"
end
