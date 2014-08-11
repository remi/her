$:.unshift File.join(File.dirname(__FILE__), *%w[.. lib])

require "rspec"
require "rspec/its"
require "her"

# Require everything in `spec/support`
Dir[File.expand_path('../../spec/support/**/*.rb', __FILE__)].map(&method(:require))

# Remove ActiveModel deprecation message
I18n.enforce_available_locales = false

RSpec.configure do |config|
  config.include Her::Testing::Macros::ModelMacros
  config.include Her::Testing::Macros::RelationMacros
  config.include Her::Testing::Macros::RequestMacros

  config.before :each do
    @spawned_classes = []
  end

  config.after :each do
    @spawned_classes.each do |klass|
      Object.instance_eval { remove_const klass } if Object.const_defined?(klass)
    end
  end
end
