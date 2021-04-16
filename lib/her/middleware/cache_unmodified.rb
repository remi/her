# Easy way to begin support 304 status, so on ther side if data was not changed
# You will load it from local cache. Of course, other side must support
# Of course, other side must support 304 status also.
# Here is Rails controller example with this support:
#
# class Post < ApplicationController
#   before_action :check_changes
#
#   private
#
#   def check_changes
#     return unless request.headers['HTTP_IF_MODIFIED_SINCE']
#     return if request.headers['HTTP_IF_MODIFIED_SINCE'].to_datetime > resource.updated_at
#     render body: nil, status: 304
#   end
# end
class Her::Middleware::CacheUnmodified < Faraday::Middleware
  SAVE_METHODS = [:get, :head].freeze

  attr_reader :cache, :options
  attr_accessor :url

  # apply with optinos:
  # cache                 # default value is Rails.cache if Rails is used
  # cache_key_prefix      # defauilt is nil

  def initialize(app, options={})
    @app = app
    @cache = options[:cache] 
    @cache ||= Rails.cache if defined?(Rails)
    @options = options
  end

  def call(env)
    return @app.call(env) unless SAVE_METHODS.include?(env[:method])
    self.url = env.url.to_s
    env[:request_headers]["If-Modified-Since"] ||= cached_time if cached_time

    @app.call(env).on_complete do
      if env[:status] == 304
        if cached_body
          env[:body] = cached_body
          # with out this hack Her crushes
          env[:status] = 200
        end
      elsif env[:status] == 200
        cache.write cache_key_body, env[:body], expires_in: cache_key_ttl
        cache.write cache_key_time, Time.zone.now.httpdate, expires_in: cache_key_ttl
      end
    end
  end

  private

  def cache_key_time
    [options[:cache_key_prefix], "time", url].compact.join("/")
  end

  def cache_key_body
    [options[:cache_key_prefix], "body", url].compact.join("/")
  end

  def cached_time
    cache.read(cache_key_time)
  end

  def cached_body
    cache.read(cache_key_body)
  end

  def cache_key_ttl
    1.week.freeze
  end
end
