# Bundler setup
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)
require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
Bundler.require(:default, ENV['RACK_ENV']) if defined? Bundler

# Require libraries
Dir[File.expand_path('../../lib/**/*.rb', __FILE__)].each do |file|
  dirname = File.dirname(file)
  file_basename = File.basename(file, File.extname(file))
  require "#{dirname}/#{file_basename}"
end

# Configure Her
Her::API.setup :url => "http://0.0.0.0:3100" do |c|
  c.use Faraday::Request::UrlEncoded
  c.use Her::Middleware::DefaultParseJSON
  c.use ResponseBodyLogger, $logger
  c.use Faraday::Response::Logger, $logger
  c.use Faraday::Adapter::NetHttp
end

# Require models
Dir[File.expand_path('../../app/models/**/*.rb', __FILE__)].each do |file|
  dirname = File.dirname(file)
  file_basename = File.basename(file, File.extname(file))
  require "#{dirname}/#{file_basename}"
end

# Application setup
require File.expand_path('../../app/consumer',  __FILE__)
