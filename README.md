# Her [![Build Status](https://secure.travis-ci.org/remiprev/her.png)](http://travis-ci.org/remiprev/her) [![Gem dependency status](https://gemnasium.com/remiprev/her.png?travis)](https://gemnasium.com/remiprev/her)

Her is an ORM (Object Relational Mapper) that maps REST resources to Ruby objects. It is designed to build applications that are powered by a RESTful API instead of a database.

## Installation

In your Gemfile, add:

```ruby
gem "her"
```

That’s it!

## Upgrade

Please see the [UPGRADE.md](https://github.com/remiprev/her/blob/master/UPGRADE.md) file for backward compability issues.

## Usage

First, you have to define which API your models will be bound to. For example, with Rails, you would create a new `config/initializers/her.rb` file with these lines:

```ruby
# config/initializers/her.rb
Her::API.setup :url => "https://api.example.com" do |connection|
  connection.use Faraday::Request::UrlEncoded
  connection.use Her::Middleware::DefaultParseJSON
  connection.use Faraday::Adapter::NetHttp
end
```

And then to add the ORM behavior to a class, you just have to include `Her::Model` in it:

```ruby
class User
  include Her::Model
end
```

After that, using Her is very similar to many ActiveModel-like ORMs:

```ruby
User.all
# GET https://api.example.com/users and return an array of User objects

User.find(1)
# GET https://api.example.com/users/1 and return a User object

@user = User.create(:fullname => "Tobias Fünke")
# POST "https://api.example.com/users" with the data and return a User object

@user = User.new(:fullname => "Tobias Fünke")
@user.occupation = "actor"
@user.save
# POST https://api.example.com/users with the data and return a User object

@user = User.find(1)
@user.fullname = "Lindsay Fünke"
@user.save
# PUT https://api.example.com/users/1 with the data and return+update the User object
```

You can look into the `examples` directory for sample applications using Her.

## Middleware

Since Her relies on [Faraday](https://github.com/technoweenie/faraday) to send HTTP requests, you can choose the middleware used to handle requests and responses. Using the block in the `setup` call, you have access to Faraday’s `connection` object and are able to customize the middleware stack used on each request and response.

### Authentication

Her doesn’t support authentication by default. However, it’s easy to implement one with request middleware. Using the `connection` block, we can add it to the middleware stack.

For example, to add a API token header to your requests, you would do something like this:

```ruby
class TokenAuthentication < Faraday::Middleware
  def initialize(app, options={})
    @options = options
  end

  def call(env)
    env[:request_headers]["X-API-Token"] = @options[:token] if @options.include?(:token)
    @app.call(env)
  end
end

Her::API.setup :url => "https://api.example.com" do |connection|
  # This token could be stored in the client session
  connection.use TokenAuthentication, :token => "bb2b2dd75413d32c1ac421d39e95b978d1819ff611f68fc2fdd5c8b9c7331192"

  connection.use Faraday::Request::UrlEncoded
  connection.use Her::Middleware::DefaultParseJSON
  connection.use Faraday::Adapter::NetHttp
end
```

Now, each HTTP request made by Her will have the `X-API-Token` header.

### Parsing JSON data

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

### OAuth

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

### Caching

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

## Relationships

You can define `has_many`, `has_one` and `belongs_to` relationships in your models. The relationship data is handled in two different ways.

1. If Her finds relationship data when parsing a resource, that data will be used to create the associated model objects on the resource.
2. If no relationship data was included when parsing a resource, calling a method with the same name as the relationship will fetch the data (providing there’s an HTTP request available for it in the API).

For example:

```ruby
class User
  include Her::Model
  has_many :comments
  has_one :role
  belongs_to :organization
end

class Comment
  include Her::Model
end

class Role
  include Her::Model
end

class Organization
  include Her::Model
end
```

If there’s relationship data in the resource, no extra HTTP request is made when calling the `#comments` method and an array of resources is returned:

```ruby
@user = User.find(1) 
# { 
#   :data => {
#     :id => 1,
#     :name => "George Michael Bluth",
#     :comments => [
#       { :id => 1, :text => "Foo" },
#       { :id => 2, :text => "Bar" }
#     ],
#     :role => { :id => 1, :name => "Admin" },
#     :organization => { :id => 2, :name => "Bluth Company" }
#   }
# }
@user.comments
# [#<Comment id=1 text="Foo">, #<Comment id=2 text="Bar">]
@user.role
# #<Role id=1 name="Admin">
@user.organization
# #<Organization id=2 name="Bluth Company">
```

If there’s no relationship data in the resource, Her makes a HTTP request to retrieve the data.

```ruby
@user = User.find(1)
# { :data => { :id => 1, :name => "George Michael Bluth", :organization_id => 2 }}

# has_many relationship:
@user.comments
# GET /users/1/comments
# [#<Comment id=1>, #<Comment id=2>]

# has_one relationship:
@user.role
# GET /users/1/role
# #<Role id=1>

# belongs_to relationship:
@user.organization
# (the organization id comes from :organization_id, by default)
# GET /organizations/2
# #<Organization id=2>
```

Subsequent calls to `#comments`, `#role` and `#organization` will not trigger extra HTTP requests and will return the cached objects.

## Hooks

You can add *before* and *after* hooks to your models that are triggered on specific actions (`save`, `update`, `create`, `destroy`):

```ruby
class User
  include Her::Model
  before_save :set_internal_id

  def set_internal_id
    self.internal_id = 42 # Will be passed in the HTTP request
  end
end

@user = User.create(:fullname => "Tobias Fünke")
# POST /users&fullname=Tobias+Fünke&internal_id=42
```

## Custom requests

You can easily define custom requests for your models using `custom_get`, `custom_post`, etc.

```ruby
class User
  include Her::Model
  custom_get :popular, :unpopular
  custom_post :from_default
end

User.popular
# GET /users/popular
# [#<User id=1>, #<User id=2>]

User.unpopular
# GET /users/unpopular
# [#<User id=3>, #<User id=4>]

User.from_default(:name => "Maeby Fünke")
# POST /users/from_default?name=Maeby+Fünke
# #<User id=5 name="Maeby Fünke">
```

You can also use `get`, `post`, `put` or `delete` (which maps the returned data to either a collection or a resource).

```ruby
class User
  include Her::Model
end

User.get(:popular)
# GET /users/popular
# [#<User id=1>, #<User id=2>]

User.get(:single_best)
# GET /users/single_best
# #<User id=1>
```

Also, `get_collection` (which maps the returned data to a collection of resources), `get_resource` (which maps the returned data to a single resource) or `get_raw` (which yields the parsed data return from the HTTP request) can also be used. Other HTTP methods are supported (`post_raw`, `put_resource`, etc.).

```ruby
class User
  include Her::Model

  def self.popular
    get_collection(:popular)
  end

  def self.total
    get_raw(:stats) do |parsed_data|
      parsed_data[:data][:total_users]
    end
  end
end

User.popular
# GET /users/popular
# [#<User id=1>, #<User id=2>]
User.total
# GET /users/stats
# => 42
```

You can also use full request paths (with strings instead of symbols).

```ruby
class User
  include Her::Model
end

User.get("/users/popular")
# GET /users/popular
# [#<User id=1>, #<User id=2>]
```

## Custom paths

You can define custom HTTP paths for your models:

```ruby
class User
  include Her::Model
  collection_path "/hello_users/:id"
end

@user = User.find(1)
# GET /hello_users/1
```

You can also include custom variables in your paths:

```ruby
class User
  include Her::Model
  collection_path "/organizations/:organization_id/users"
end

@user = User.find(1, :_organization_id => 2)
# GET /organizations/2/users/1

@user = User.all(:_organization_id => 2)
# GET /organizations/2/users

@user = User.new(:fullname => "Tobias Fünke", :organization_id => 2)
@user.save
# POST /organizations/2/users
```

## Multiple APIs

It is possible to use different APIs for different models. Instead of calling `Her::API.setup`, you can create instances of `Her::API`:

```ruby
# config/initializers/her.rb
$my_api = Her::API.new
$my_api.setup :url => "https://my_api.example.com" do |connection|
  connection.use Faraday::Request::UrlEncoded
  connection.use Her::Middleware::DefaultParseJSON
  connection.use Faraday::Adapter::NetHttp
end

$other_api = Her::API.new
$other_api.setup :url => "https://other_api.example.com" do |connection|
  connection.use Faraday::Request::UrlEncoded
  connection.use Her::Middleware::DefaultParseJSON
  connection.use Faraday::Adapter::NetHttp
end
```

You can then define which API a model will use:

```ruby
class User
  include Her::Model
  uses_api $my_api
end

class Category
  include Her::Model
  uses_api $other_api
end

User.all
# GET https://my_api.example.com/users

Category.all
# GET https://other_api.example.com/categories
```

## SSL

When initializing `Her::API`, you can pass any parameter supported by `Faraday.new`. So [to use HTTPS](https://github.com/technoweenie/faraday/wiki/Setting-up-SSL-certificates), you can use Faraday’s `:ssl` option.

```ruby
ssl_options = { :ca_path => "/usr/lib/ssl/certs" }
Her::API.setup :url => "https://api.example.com", :ssl => ssl_options do |connection|
  connection.use Faraday::Request::UrlEncoded
  connection.use Her::Middleware::DefaultParseJSON
  connection.use Faraday::Adapter::NetHttp
end
```

## Testing

Using Faraday stubbing feature, it’s very easy to write tests for our models. For example, using [RSpec](https://github.com/rspec/rspec-core):

```ruby
# app/models/post.rb
class Post
  include Her::Model
  custom_get :popular
end

# spec/models/post.rb
describe Post do
  before do
    Her::API.setup :url => "http://api.example.com" do |connection|
      connection.use Her::Middleware::FirstLevelParseJSON
      connection.use Faraday::Request::UrlEncoded
      connection.adapter :test do |stub|
        stub.get("/users/popular") { |env| [200, {}, [{ :id => 1, :name => "Tobias Fünke" }, { :id => 2, :name => "Lindsay Fünke" }].to_json] }
      end
    end
  end

  describe ".popular" do
    it "should fetch all popular posts" do
      @posts = Post.popular
      @posts.length.should == 2
    end
  end
end
```

## Things to be done

* Better error handling
* Better API documentation (using YARD)

## Contribute

Yes please! Feel free to contribute and submit issues/pull requests [on GitHub](https://github.com/remiprev/her/issues).

### How to contribute

* Fork the repository
* Implement your feature or fix
* Add examples that describe it (in the `spec` directory)
* Make sure `bundle exec rake spec` passes after your modifications
* Commit (bonus points for doing it in a `feature-*` branch)
* Send a pull request!

### Contributors

These fine folks helped with Her:

* [@jfcixmedia](https://github.com/jfcixmedia)
* [@EtienneLem](https://github.com/EtienneLem)
* [@rafaelss](https://github.com/rafaelss)
* [@tysontate](https://github.com/tysontate)
* [@nfo](https://github.com/nfo)
* [@simonprevost](https://github.com/simonprevost)

## License

Her is © 2012 [Rémi Prévost](http://exomel.com) and may be freely distributed under the [MIT license](https://github.com/remiprev/her/blob/master/LICENSE). See the `LICENSE` file.
