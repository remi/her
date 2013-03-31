$:.unshift File.join(File.dirname(__FILE__), *%w[.. lib])

require "rspec"
require "mocha/api"
require "yajl"
require "her"

Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  config.mock_with :mocha

  config.before :each do
    @globals = []
  end

  config.after :each do
    @globals.each do |global|
      Object.instance_eval { remove_const global } if Object.const_defined?(global)
    end
  end

  config.include(Module.new do
    def stub_api_for(klass)
      if klass.is_a?(String)
        spawn_model(klass)
        klass = klass.constantize
      end

      klass.uses_api (api = Her::API.new)

      # Taken straight from Her's README.md!
      api.setup :url => "http://api.example.com" do |c|
        c.use Faraday::Request::UrlEncoded
        c.use Her::Middleware::FirstLevelParseJSON
        c.adapter(:test) { |s| yield(s) }
      end
    end
  end)

  config.include Her::Testing::Macros
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
    submodel
  else
    Object.instance_eval { remove_const klass } if Object.const_defined?(klass)
    Object.const_set(klass, Class.new).send(:include, Her::Model)
    Object.const_get(klass).class_eval(&block) if block_given?
    @globals << klass.to_sym
    Object.const_get(klass)
  end
end
