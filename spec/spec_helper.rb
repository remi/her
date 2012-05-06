$:.unshift File.join(File.dirname(__FILE__), *%w[.. lib])

require "her"
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

def spawn_model(klass, &block)
  if klass =~ /::/
    base, submodel = klass.split(/::/).map{ |s| s.to_sym }
    Object.const_set(base, Module.new) unless Object.const_defined?(base)
    Object.const_get(base).module_eval do
      remove_const submodel if constants.include?(submodel)
      const_set(submodel, Class.new).send(:include, Her::Model)
    end
  else
    Object.instance_eval { remove_const klass } if Object.const_defined?(klass)
    Object.const_set(klass, Class.new).send(:include, Her::Model)
    Object.const_get(klass).class_eval(&block) if block_given?
  end
end
