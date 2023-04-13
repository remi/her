require "restorm/version"

require "multi_json"
require "faraday"
require "active_support"
require "active_support/inflector"
require "active_support/core_ext/hash"

require "restorm/model"
require "restorm/api"
require "restorm/middleware"
require "restorm/errors"
require "restorm/collection"

module Restorm
  module JsonApi
    autoload :Model, 'restorm/json_api/model'
  end
end
