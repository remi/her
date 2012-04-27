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
  def to_json; MultiJson.dump(self); end
end

class Array
  def to_json; MultiJson.dump(self); end
end

def spawn_model(klass, attrs={}, &block)
  Object.instance_eval { remove_const klass } if Object.const_defined?(klass)
  Object.const_set(klass, Class.new).send(:include, Her::Model)
  Object.const_get(klass).class_eval(&block) if block_given?
end
