# Features

## Methods

```ruby
class User
  include Her::Model
end

# Update a fetched resource
user = User.find(1)
user.fullname = "Lindsay Fünke"
# OR user.assign_attributes :fullname => "Lindsay Fünke"
user.save

# Update a resource without fetching it
User.save_existing(1, :fullname => "Lindsay Fünke")

# Destroy a fetched resource
user = User.find(1)
user.destroy

# Destroy a resource without fetching it
User.destroy_existing(1)

# Fetching a collection of resources
User.all

# Create a new resource
User.create(:fullname => "Maeby Fünke")

# Save a new resource
user = User.new(:fullname => "Maeby Fünke")
user.save
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
