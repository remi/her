require "her/version"

require "multi_json"
require "faraday"
require "active_support"
require "active_support/inflector"
require "active_support/core_ext/hash"

require "her/model"
require "her/api"
require "her/middleware"
require "her/errors"
require "her/collection"

module Her
  module JsonApi
    autoload :Model, 'her/json_api/model'
  end
end
