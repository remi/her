$:.unshift File.join(File.dirname(__FILE__), *%w[.. lib])

require "her"
require "fakeweb"
require "mocha"

module Helpers
end

RSpec.configure do |c|
  c.include Helpers
end

class Hash
  def to_json
    MultiJson.dump(self)
  end
end

def spawn_model(klass, attrs={})
  Object.instance_eval { remove_const klass } if Object.const_defined?(klass)
  eval "class #{klass}; include Her::Model; end"
end
