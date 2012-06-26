$:.unshift File.join(File.dirname(__FILE__), *%w[.. lib])

require "her"
require "mocha"

RSpec.configure do |c|
  c.before :each do
    @globals = []
  end

  c.after :each do
    @globals.each do |global|
      Object.instance_eval { remove_const global } if Object.const_defined?(global)
    end
  end
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
      submodel = const_set(submodel, Class.new)
      submodel.send(:include, Her::Model)
      submodel.class_eval(&block) if block_given?
    end
    @globals << base
  else
    Object.instance_eval { remove_const klass } if Object.const_defined?(klass)
    Object.const_set(klass, Class.new).send(:include, Her::Model)
    Object.const_get(klass).class_eval(&block) if block_given?
    @globals << klass.to_sym
  end
end
