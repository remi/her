# Middleware

Since Her relies on [Faraday](https://github.com/technoweenie/faraday) to send HTTP requests, you can choose the middleware used to handle requests and responses. Using the block in the `setup` call, you have access to Faraday’s `connection` object and are able to customize the middleware stack used on each request and response.

## Authentication

Her doesn’t support authentication by default. However, it’s easy to implement one with request middleware. Using the `connection` block, we can add it to the middleware stack.

For example, to add a API token header to your requests in a Rails application, you would do something like this:

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  around_filter :do_with_authenticated_user

  def do_with_authenticated_user
    Thread.current[:my_api_token] = session[:my_api_token]
    begin
      yield
    ensure
      Thread.current[:my_access_token] = nil
    end
  end
end

# lib/my_token_authentication.rb
class MyTokenAuthentication < Faraday::Middleware
  def initialize(app, options={})
    @app = app
  end

  def call(env)
    env[:request_headers]["X-API-Token"] = Thread.current[:my_api_token] if Thread.current[:my_api_token].present?
    @app.call(env)
  end
end

# config/initializers/her.rb
require "lib/my_token_authentication"

Her::API.setup :url => "https://api.example.com" do |connection|
  connection.use MyTokenAuthentication
  connection.use Faraday::Request::UrlEncoded
  connection.use Her::Middleware::DefaultParseJSON
  connection.use Faraday::Adapter::NetHttp
end
```

Now, each HTTP request made by Her will have the `X-API-Token` header.

## Parsing JSON data

By default, Her handles JSON data. It expects the resource/collection data to be returned at the first level.

```javascript
// The response of GET /users/1
{ "id" : 1, "name" : "Tobias Fünke" }

// The response of GET /users
[{ "id" : 1, "name" : "Tobias Fünke" }]
```

However, you can define your own parsing method using a response middleware. The middleware should set `env[:body]` to a hash with three keys: `data`, `errors` and `metadata`. The following code uses a custom middleware to parse the JSON data:

```ruby
# Expects responses like:
#
#     {
#       "result": {
#         "id": 1,
#         "name": "Tobias Fünke"
#       },
#       "errors" => []
#     }
#
class MyCustomParser < Faraday::Response::Middleware
  def on_complete(env)
    json = MultiJson.load(env[:body], :symbolize_keys => true)
    env[:body] = {
      :data => json[:result],
      :errors => json[:errors],
      :metadata => json[:metadata]
    }
  end
end

Her::API.setup :url => "https://api.example.com" do |connection|
  connection.use Faraday::Request::UrlEncoded
  connection.use MyCustomParser
  connection.use Faraday::Adapter::NetHttp
end
```

## OAuth

Using the `faraday_middleware` and `simple_oauth` gems, it’s fairly easy to use OAuth authentication with Her.

In your Gemfile:

```ruby
gem "her"
gem "faraday_middleware"
gem "simple_oauth"
```

In your Ruby code:

```ruby
# Create an application on `https://dev.twitter.com/apps` to set these values
TWITTER_CREDENTIALS = {
  :consumer_key => "",
  :consumer_secret => "",
  :token => "",
  :token_secret => ""
}

Her::API.setup :url => "https://api.twitter.com/1/" do |connection|
  connection.use FaradayMiddleware::OAuth, TWITTER_CREDENTIALS
  connection.use Faraday::Request::UrlEncoded
  connection.use Her::Middleware::DefaultParseJSON
  connection.use Faraday::Adapter::NetHttp
end

class Tweet
  include Her::Model
end

@tweets = Tweet.get("/statuses/home_timeline.json")
```

See the *Authentication* middleware section for an example of how to pass different credentials based on the current user.

## Caching

Again, using the `faraday_middleware` makes it very easy to cache requests and responses:

In your Gemfile:

```ruby
gem "her"
gem "faraday_middleware"
```

In your Ruby code:

```ruby
class MyCache < Hash
  def read(key)
    if cached = self[key]
      Marshal.load(cached)
    end
  end

  def write(key, data)
    self[key] = Marshal.dump(data)
  end

  def fetch(key)
    read(key) || yield.tap { |data| write(key, data) }
  end
end

# A cache system must respond to `#write`, `#read` and `#fetch`.
# We should be probably using something like Memcached here, not a global object
$cache = MyCache.new

Her::API.setup :url => "https://api.example.com" do |connection|
  connection.use Faraday::Request::UrlEncoded
  connection.use FaradayMiddleware::Caching, $cache
  connection.use Her::Middleware::DefaultParseJSON
  connection.use Faraday::Adapter::NetHttp
end

class User
  include Her::Model
end

@user = User.find(1)
# GET /users/1

@user = User.find(1)
# This request will be fetched from the cache
```

Caching with Memcached (simple way)

```ruby

# In your gemfile add 

gem "memcached"

# initializers/her.rb

require "memcached"

$cache = Memcached::Rails.new("localhost:11211")

Her::API.setup :url => "https://api.example.com" do |connection|
  connection.use Faraday::Request::UrlEncoded
  connection.use FaradayMiddleware::Caching, $cache
  connection.use Her::Middleware::DefaultParseJSON
  connection.use Faraday::Adapter::NetHttp
end

```
