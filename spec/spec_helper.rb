$:.unshift File.join(File.dirname(__FILE__), *%w[.. lib])

require "her"

module Helpers
end

RSpec.configure do |c|
  c.include Helpers
end
