# Her

[![Gem Version](https://badge.fury.io/rb/her.png)](https://rubygems.org/gems/her)
[![Build Status](https://secure.travis-ci.org/remiprev/her.png?branch=master)](http://travis-ci.org/remiprev/her)
[![Dependency Status](https://gemnasium.com/remiprev/her.png?travis)](https://gemnasium.com/remiprev/her)
[![Code Climate](https://codeclimate.com/github/remiprev/her.png)](https://codeclimate.com/github/remiprev/her)

Her is an ORM (Object Relational Mapper) that maps REST resources to Ruby objects. It is designed to build applications that are powered by a RESTful API instead of a database.

## Installation

In your Gemfile, add:

```ruby
gem "her"
```

That’s it!

## Usage

_For a complete reference of all the methods you can use, check out [the documentation](http://rdoc.info/github/remiprev/her)._

First, you have to define which API your models will be bound to. For example, with Rails, you would create a new `config/initializers/her.rb` file with these lines:

```ruby
# config/initializers/her.rb
Her::API.setup url: "https://api.example.com" do |c|
  c.use Faraday::Request::UrlEncoded
  c.use Her::Middleware::DefaultParseJSON
  c.use Faraday::Adapter::NetHttp
end
```

And then to add the ORM behavior to a class, you just have to include `Her::Model` in it:

```ruby
class User
  include Her::Model
end
```

After that, using Her is very similar to many ActiveRecord-like ORMs:

```ruby
User.all
# GET "https://api.example.com/users" and return an array of User objects

User.find(1)
# GET "https://api.example.com/users/1" and return a User object

@user = User.create(fullname: "Tobias Fünke")
# POST "https://api.example.com/users" with `fullname=Tobias+Fünke` and return the saved User object

@user = User.new(fullname: "Tobias Fünke")
@user.occupation = "actor"
@user.save
# POST "https://api.example.com/users" with `fullname=Tobias+Fünke&occupation=actor` and return the saved User object

@user = User.find(1)
@user.fullname = "Lindsay Fünke"
@user.save
# PUT "https://api.example.com/users/1" with `fullname=Lindsay+Fünke` and return the updated User object
```

### ActiveRecord-like methods

These are the basic ActiveRecord-like methods you can use with your models:

```ruby
class User
  include Her::Model
end

# Update a fetched resource
user = User.find(1)
user.fullname = "Lindsay Fünke" # OR user.assign_attributes(fullname: "Lindsay Fünke")
user.save # returns false if it fails, errors in user.response_errors array
# PUT "/users/1" with `fullname=Lindsay+Fünke`

# Update a resource without fetching it
User.save_existing(1, fullname: "Lindsay Fünke")
# PUT "/users/1" with `fullname=Lindsay+Fünke`

# Destroy a fetched resource
user = User.find(1)
user.destroy
# DELETE "/users/1"

# Destroy a resource without fetching it
User.destroy_existing(1)
# DELETE "/users/1"

# Fetching a collection of resources
User.all
# GET "/users"
User.where(moderator: 1).all
# GET "/users?moderator=1"

# Create a new resource
User.create(fullname: "Maeby Fünke")
# POST "/users" with `fullname=Maeby+Fünke`

# Save a new resource
user = User.new(fullname: "Maeby Fünke")
user.save! # raises Her::Errors::ResourceInvalid if it fails
# POST "/users" with `fullname=Maeby+Fünke`
```

You can look into the [`her-example`](https://github.com/remiprev/her-example) repository for a sample application using Her.

## Middleware

Since Her relies on [Faraday](https://github.com/lostisland/faraday) to send HTTP requests, you can choose the middleware used to handle requests and responses. Using the block in the `setup` call, you have access to Faraday’s `connection` object and are able to customize the middleware stack used on each request and response.

### Authentication

Her doesn’t support authentication by default. However, it’s easy to implement one with request middleware. Using the `setup` block, we can add it to the middleware stack.

For example, to add a token header to your API requests in a Rails application, you could use the excellent [`request_store`](https://rubygems.org/gems/request_store) gem like this:

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_filter :set_user_api_token

  protected
  def set_user_api_token
    RequestStore.store[:my_api_token] = current_user.api_token # or something similar based on `session`
  end
end

# lib/my_token_authentication.rb
class MyTokenAuthentication < Faraday::Middleware
  def call(env)
    env[:request_headers]["X-API-Token"] = RequestStore.store[:my_api_token]
    @app.call(env)
  end
end

# config/initializers/her.rb
require "lib/my_token_authentication"

Her::API.setup url: "https://api.example.com" do |c|
  c.use MyTokenAuthentication
  c.use Faraday::Request::UrlEncoded
  c.use Her::Middleware::DefaultParseJSON
  c.use Faraday::Adapter::NetHttp
end
```

Now, each HTTP request made by Her will have the `X-API-Token` header.

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
  consumer_key: "",
  consumer_secret: "",
  token: "",
  token_secret: ""
}

Her::API.setup url: "https://api.twitter.com/1/" do |c|
  c.use FaradayMiddleware::OAuth, TWITTER_CREDENTIALS
  c.use Her::Middleware::DefaultParseJSON
  c.use Faraday::Adapter::NetHttp
end

class Tweet
  include Her::Model
end

@tweets = Tweet.get("/statuses/home_timeline.json")
```

See the *Authentication* middleware section for an example of how to pass different credentials based on the current user.

### Parsing JSON data

By default, Her handles JSON data. It expects the resource/collection data to be returned at the first level.

```javascript
// The response of GET /users/1
{ "id" : 1, "name" : "Tobias Fünke" }

// The response of GET /users
[{ "id" : 1, "name" : "Tobias Fünke" }]
```

However, if you want Her to be able to parse the data from a single root element (usually based on the model name), you’ll have to use the `parse_root_in_json` method (See the **JSON attributes-wrapping** section).

Also, you can define your own parsing method using a response middleware. The middleware should set `env[:body]` to a hash with three symbol keys: `:data`, `:errors` and `:metadata`. The following code uses a custom middleware to parse the JSON data:

```ruby
# Expects responses like:
#
#     {
#       "result": { "id": 1, "name": "Tobias Fünke" },
#       "errors": []
#     }
#
class MyCustomParser < Faraday::Response::Middleware
  def on_complete(env)
    json = MultiJson.load(env[:body], symbolize_keys: true)
    env[:body] = {
      data: json[:result],
      errors: json[:errors],
      metadata: json[:metadata]
    }
  end
end

Her::API.setup url: "https://api.example.com" do |c|
  c.use MyCustomParser
  c.use Faraday::Adapter::NetHttp
end
```

### Caching

Again, using the `faraday_middleware` and `memcached` gems makes it very easy to cache requests and responses.

In your Gemfile:

```ruby
gem "her"
gem "faraday_middleware"
gem "memcached"
```

In your Ruby code:

```ruby
Her::API.setup url: "https://api.example.com" do |c|
  c.use FaradayMiddleware::Caching, Memcached::Rails.new('127.0.0.1:11211')
  c.use Her::Middleware::DefaultParseJSON
  c.use Faraday::Adapter::NetHttp
end

class User
  include Her::Model
end

@user = User.find(1)
# GET "/users/1"

@user = User.find(1)
# This request will be fetched from memcached
```

## Advanced Features

Here’s a list of several useful features available in Her.

### Associations

Examples use this code:

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

#### Fetching data

You can define `has_many`, `has_one` and `belongs_to` associations in your models. The association data is handled in two different ways.

1. If Her finds association data when parsing a resource, that data will be used to create the associated model objects on the resource.
2. If no association data was included when parsing a resource, calling a method with the same name as the association will fetch the data (providing there’s an HTTP request available for it in the API).

For example, if there’s association data in the resource, no extra HTTP request is made when calling the `#comments` method and an array of resources is returned:

```ruby
@user = User.find(1)
# GET "/users/1", response is:
# {
#   "id": 1,
#   "name": "George Michael Bluth",
#   "comments": [
#     { "id": 1, "text": "Foo" },
#     { "id": 2, "text": "Bar" }
#   ],
#   "role": { "id": 1, "name": "Admin" },
#   "organization": { "id": 2, "name": "Bluth Company" }
# }

@user.comments
# => [#<Comment id=1 text="Foo">, #<Comment id=2 text="Bar">]

@user.role
# => #<Role id=1 name="Admin">

@user.organization
# => #<Organization id=2 name="Bluth Company">
```

If there’s no association data in the resource, Her makes a HTTP request to retrieve the data.

```ruby
@user = User.find(1)
# GET "/users/1", response is { "id": 1, "name": "George Michael Bluth", "organization_id": 2 }

# has_many association:
@user.comments
# GET "/users/1/comments"
# => [#<Comment id=1>, #<Comment id=2>]

@user.comments.where(approved: 1)
# GET "/users/1/comments?approved=1"
# => [#<Comment id=1>]

# has_one association:
@user.role
# GET "/users/1/role"
# => #<Role id=1>

# belongs_to association:
@user.organization
# (the organization id comes from :organization_id, by default)
# GET "/organizations/2"
# => #<Organization id=2>
```

Subsequent calls to `#comments`, `#role` and `#organization` will not trigger extra HTTP requests and will return the cached objects.

#### Creating data

You can use the association methods to build new objects and save them.

```ruby
@user = User.find(1)
@user.comments.build(body: "Just a draft")
# => [#<Comment body="Just a draft" user_id=1>]

@user.comments.create(body: "Hello world.")
# POST "/users/1/comments" with `body=Hello+world.`
# => [#<Comment id=3 body="Hello world." user_id=1>]
```

You can also explicitly request a new object via the API when using ``build``. This is useful if you're dealing with default attributes.

```ruby
class Comment
  include Her::Model
  request_new_object_on_build true
end

@user = User.find(1)
@user.comments.build(body: "Just a draft")
# GET "/users/1/comments/new" with `body=Just+a+draft.`
# => [#<Comment id=nil body="Just a draft" archived=false user_id=1>]
```

#### Notes about paths

Resources must always have all the required attributes to build their complete path. For example, if you have these models:

```ruby
class User
  include Her::Model
  collection_path "organizations/:organization_id/users"
end

class Organization
  include Her::Model
  has_many :users
end
```

Her expects all `User` resources to have an `:organization_id` (or `:_organization_id`) attribute. Otherwise, calling mostly all methods, like `User.all`, will thrown an exception like this one:

```ruby
Her::Errors::PathError: Missing :_organization_id parameter to build the request path. Path is `organizations/:organization_id/users`. Parameters are `{ … }`.
```

### Validations

Her includes `ActiveModel::Validations` so you can declare validations the same way you do in Rails.

However, validations must be triggered manually — they are not run, for example, when calling `#save` on an object, or `#create` on a model class.

```ruby
class User
  include Her::Model

  attributes :fullname, :email
  validates :fullname, presence: true
  validates :email, presence: true
end

@user = User.new(fullname: "Tobias Fünke")
@user.valid? # => false

@user.save
# POST "/users" with `fullname=Tobias+Fünke` will still be called, even if the user is not valid
```

### Dirty attributes

Her includes `ActiveModel::Dirty` so you can keep track of the attributes that have changed in an object.

```ruby
class User
  include Her::Model

  attributes :fullname, :email
end

@user = User.new(fullname: "Tobias Fünke")
@user.fullname_changed? # => true
@user.changes # => { :fullname => [nil, "Tobias Fünke"] }

@user.save
# POST "/users" with `fullname=Tobias+Fünke`

@user.fullname_changed? # => false
@user.changes # => {}
```

### Callbacks

You can add *before* and *after* callbacks to your models that are triggered on specific actions. You can use symbols or blocks.

```ruby
class User
  include Her::Model
  before_save :set_internal_id
  after_find { |u| u.fullname.upcase! }

  def set_internal_id
    self.internal_id = 42 # Will be passed in the HTTP request
  end
end

@user = User.create(fullname: "Tobias Fünke")
# POST "/users" with `fullname=Tobias+Fünke&internal_id=42`

@user = User.find(1)
@user.fullname # => "TOBIAS FUNKE"
```

The available callbacks are:

* `before_save`
* `before_create`
* `before_update`
* `before_destroy`
* `after_save`
* `after_create`
* `after_update`
* `after_destroy`
* `after_find`
* `after_initialize`

### JSON attributes-wrapping

Her supports *sending* and *parsing* JSON data wrapped in a root element (to be compatible with Rails’ `include_root_in_json` setting), like so:

#### Sending

If you want to send all data to your API wrapped in a *root* element based on the model name.

```ruby
class User
  include Her::Model
  include_root_in_json true
end

class Article
  include Her::Model
  include_root_in_json :post
end

User.create(fullname: "Tobias Fünke")
# POST "/users" with `user[fullname]=Tobias+Fünke`

Article.create(title: "Hello world.")
# POST "/articles" with `post[title]=Hello+world`
```

#### Parsing

If the API returns data wrapped in a *root* element based on the model name.

```ruby
class User
  include Her::Model
  parse_root_in_json true
end

class Article
  include Her::Model
  parse_root_in_json :post
end

user = User.create(fullname: "Tobias Fünke")
# POST "/users" with `fullname=Tobias+Fünke`, response is { "user": { "fullname": "Tobias Fünke" } }
user.fullname # => "Tobias Fünke"

article = Article.create(title: "Hello world.")
# POST "/articles" with `title=Hello+world.`, response is { "post": { "title": "Hello world." } }
article.title # => "Hello world."
```

Of course, you can use both `include_root_in_json` and `parse_root_in_json` at the same time.

#### ActiveModel::Serializers support

If the API returns data in the default format used by the
[ActiveModel::Serializers](https://github.com/rails-api/active_model_serializers)
project you need to configure Her as follows:

```ruby
class User
  include Her::Model
  parse_root_in_json true, format: :active_model_serializers
end

user = Users.find(1)
# GET "/users/1", response is { "user": { "id": 1, "fullname": "Lindsay Fünke"} }

users = Users.all
# GET "/users", response is { "users": [{ "id": 1, "fullname": "Lindsay Fünke"}] }
```

### Custom requests

You can easily define custom requests for your models using `custom_get`, `custom_post`, etc.

```ruby
class User
  include Her::Model

  custom_get :popular, :unpopular
  custom_post :from_default
end

User.popular
# GET "/users/popular"
# => [#<User id=1>, #<User id=2>]

User.unpopular
# GET "/users/unpopular"
# => [#<User id=3>, #<User id=4>]

User.from_default(name: "Maeby Fünke")
# POST "/users/from_default" with `name=Maeby+Fünke`
# => #<User id=5 name="Maeby Fünke">
```

You can also use `get`, `post`, `put` or `delete` (which maps the returned data to either a collection or a resource).

```ruby
class User
  include Her::Model
end

User.get(:popular)
# GET "/users/popular"
# => [#<User id=1>, #<User id=2>]

User.get(:single_best)
# GET "/users/single_best"
# => #<User id=1>
```

You can also use `get_raw` which yields the parsed data and the raw response from the HTTP request. Other HTTP methods are supported (`post_raw`, `put_raw`, etc.).

```ruby
class User
  include Her::Model

  def self.total
    get_raw(:stats) do |parsed_data, response|
      parsed_data[:data][:total_users]
    end
  end
end

User.total
# GET "/users/stats"
# => 42
```

You can also use full request paths (with strings instead of symbols).

```ruby
class User
  include Her::Model
end

User.get("/users/popular")
# GET "/users/popular"
# => [#<User id=1>, #<User id=2>]
```

### Custom paths

You can define custom HTTP paths for your models:

```ruby
class User
  include Her::Model
  collection_path "/hello_users/:id"
end

@user = User.find(1)
# GET "/hello_users/1"
```

You can also include custom variables in your paths:

```ruby
class User
  include Her::Model
  collection_path "/organizations/:organization_id/users"
end

@user = User.find(1, _organization_id: 2)
# GET "/organizations/2/users/1"

@user = User.all(_organization_id: 2)
# GET "/organizations/2/users"

@user = User.new(fullname: "Tobias Fünke", organization_id: 2)
@user.save
# POST "/organizations/2/users" with `fullname=Tobias+Fünke`
```

### Custom primary keys

If your record uses an attribute other than `:id` to identify itself, specify it using the `primary_key` method:

```ruby
class User
  include Her::Model
  primary_key :_id
end

user = User.find("4fd89a42ff204b03a905c535")
# GET "/users/1", response is { "_id": "4fd89a42ff204b03a905c535", "name": "Tobias" }

user.destroy
# DELETE "/users/4fd89a42ff204b03a905c535"
```

### Inheritance

If all your models share the same settings, you might want to make them children of a class and only include `Her::Model` in that class. However, there are a few settings that don’t get passed to the children classes:

* `root_element`
* `collection_path` and `resource_path`

Those settings are based on the class name, so you don’t have to redefine them each time you create a new children class (but you still can). Every other setting is inherited from the parent (associations, scopes, JSON settings, etc.).

```ruby
module MyAPI
  class Model
    include Her::Model

    parse_root_in_json true
    include_root_in_json true
  end
end

class User < MyAPI::Model
end

User.find(1)
# GET "/users/1"
```

### Scopes

Just like with ActiveRecord, you can define named scopes for your models. Scopes are chainable and can be used within other scopes.

```ruby
class User
  include Her::Model

  scope :by_role, -> { |role| where(role: role) }
  scope :admins, -> { by_role('admin') }
  scope :active, -> { where(active: 1) }
end

@admins = User.admins
# GET "/users?role=admin"

@moderators = User.by_role('moderator')
# GET "/users?role=moderator"

@active_admins = User.active.admins # @admins.active would have worked here too
# GET "/users?role=admin&active=1"
```

A neat trick you can do with scopes is interact with complex paths.

```ruby
class User
  include Her::Model

  collection_path "organizations/:organization_id/users"
  scope :for_organization, -> { |id| where(organization_id: id) }
end

@user = User.for_organization(3).find(2)
# GET "/organizations/3/users/2"

@user = User.for_organization(3).create(fullname: "Tobias Fünke")
# POST "/organizations/3" with `fullname=Tobias+Fünke`
```

### Multiple APIs

It is possible to use different APIs for different models. Instead of calling `Her::API.setup`, you can create instances of `Her::API`:

```ruby
# config/initializers/her.rb
MY_API = Her::API.new
MY_API.setup url: "https://my-api.example.com" do |c|
  c.use Her::Middleware::DefaultParseJSON
  c.use Faraday::Adapter::NetHttp
end

OTHER_API = Her::API.new
OTHER_API.setup url: "https://other-api.example.com" do |c|
  c.use Her::Middleware::DefaultParseJSON
  c.use Faraday::Adapter::NetHttp
end
```

You can then define which API a model will use:

```ruby
class User
  include Her::Model
  use_api MY_API
end

class Category
  include Her::Model
  use_api OTHER_API
end

User.all
# GET "https://my-api.example.com/users"

Category.all
# GET "https://other-api.example.com/categories"
```

### SSL

When initializing `Her::API`, you can pass any parameter supported by `Faraday.new`. So [to use HTTPS](https://github.com/lostisland/faraday/wiki/Setting-up-SSL-certificates), you can use Faraday’s `:ssl` option.

```ruby
ssl_options = { ca_path: "/usr/lib/ssl/certs" }
Her::API.setup url: "https://api.example.com", ssl: ssl_options do |c|
  c.use Her::Middleware::DefaultParseJSON
  c.use Faraday::Adapter::NetHttp
end
```

## Testing

Suppose we have these two models bound to your API:

```ruby
# app/models/user.rb
class User
  include Her::Model
  custom_get :popular
end

# app/models/post.rb
class Post
  include Her::Model
  custom_get :recent, :archived
end
```

In order to test them, we’ll have to stub the remote API requests. With [RSpec](https://github.com/rspec/rspec-core), we can do this like so:

```ruby
# spec/spec_helper.rb
RSpec.configure do |config|
  config.include(Module.new do
    def stub_api_for(klass)
      klass.use_api (api = Her::API.new)

      # Here, you would customize this for your own API (URL, middleware, etc)
      # like you have done in your application’s initializer
      api.setup url: "http://api.example.com" do |c|
        c.use Her::Middleware::FirstLevelParseJSON
        c.adapter(:test) { |s| yield(s) }
      end
    end
  end)
end
```

Then, in your tests, we can specify what (fake) HTTP requests will return:

```ruby
# spec/models/user.rb
describe User do
  before do
    stub_api_for(User) do |stub|
      stub.get("/users/popular") { |env| [200, {}, [{ id: 1, name: "Tobias Fünke" }, { id: 2, name: "Lindsay Fünke" }].to_json] }
    end
  end

  describe :popular do
    subject { User.popular }
    its(:length) { should == 2 }
    its(:errors) { should be_empty }
  end
end
```

We can redefine the API for a model as many times as we want, like for more complex tests:

```ruby
# spec/models/user.rb
describe Post do
  describe :recent do
    before do
      stub_api_for(Post) do |stub|
        stub.get("/posts/recent") { |env| [200, {}, [{ id: 1 }, { id: 2 }].to_json] }
      end
    end

    subject { Post.recent }
    its(:length) { should == 2 }
    its(:errors) { should be_empty }
  end

  describe :archived do
    before do
      stub_api_for(Post) do |stub|
        stub.get("/posts/archived") { |env| [200, {}, [{ id: 1 }, { id: 2 }].to_json] }
      end
    end

    subject { Post.archived }
    its(:length) { should == 2 }
    its(:errors) { should be_empty }
  end
end
```

## Upgrade

See the [UPGRADE.md](https://github.com/remiprev/her/blob/master/UPGRADE.md) for backward compability issues.

## Her IRL

Most projects I know that use Her are internal or private projects but here’s a list of public ones:

* [tumbz](https://github.com/remiprev/tumbz)
* [crowdher](https://github.com/simonprev/crowdher)
* [vodka](https://github.com/magnolia-fan/vodka)
* [webistrano_cli](https://github.com/chytreg/webistrano_cli)

## History

I told myself a few months ago that it would be great to build a gem to replace Rails’ [ActiveResource](http://api.rubyonrails.org/classes/ActiveResource/Base.html) since it was barely maintained (and now removed from Rails 4.0), lacking features and hard to extend/customize. I had built a few of these REST-powered ORMs for client projects before but I decided I wanted to write one for myself that I could release as an open-source project.

Most of Her’s core concepts were written on a Saturday morning of April 2012 ([first commit](https://github.com/remiprev/her/commit/689d8e88916dc2ad258e69a2a91a283f061cbef2) at 7am!).

## Contribute

Yes please! Feel free to contribute and submit issues/pull requests [on GitHub](https://github.com/remiprev/her/issues). There’s no such thing as a bad pull request — even if it’s for a typo, a small improvement to the code or the documentation!

See [CONTRIBUTING.md](https://github.com/remiprev/her/blob/master/CONTRIBUTING.md) for best practices.

### Contributors

These [fine folks](https://github.com/remiprev/her/contributors) helped with Her:

* [@jfcixmedia](https://github.com/jfcixmedia)
* [@EtienneLem](https://github.com/EtienneLem)
* [@rafaelss](https://github.com/rafaelss)
* [@tysontate](https://github.com/tysontate)
* [@nfo](https://github.com/nfo)
* [@simonprevost](https://github.com/simonprevost)
* [@jmlacroix](https://github.com/jmlacroix)
* [@thomsbg](https://github.com/thomsbg)
* [@calmyournerves](https://github.com/calmyournerves)
* [@luflux](https://github.com/luxflux)
* [@simonc](https://github.com/simonc)
* [@pencil](https://github.com/pencil)
* [@joanniclaborde](https://github.com/joanniclaborde)
* [@seanreads](https://github.com/seanreads)
* [@jonkarna](https://github.com/jonkarna)
* [@aclevy](https://github.com/aclevy)
* [@stevschmid](https://github.com/stevschmid)
* [@prognostikos](https://github.com/prognostikos)

## License

Her is © 2012-2013 [Rémi Prévost](http://exomel.com) and may be freely distributed under the [MIT license](https://github.com/remiprev/her/blob/master/LICENSE). See the `LICENSE` file.
