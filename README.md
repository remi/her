# Her

[![Build Status](https://secure.travis-ci.org/remiprev/her.png)](http://travis-ci.org/remiprev/her)

Her is an ORM (Object Relational Mapper) that maps REST resources to Ruby objects. It is designed to build applications that are powered by a RESTful API.

## Installation

In your Gemfile, add:

```ruby
gem "her"
```

That’s it!

## Usage

First, you have to define which API your models will be bound to. For example, with Rails, you would create a new `config/initializers/her.rb` file with this line:

```ruby
Her::API.setup :base_uri => "https://api.example.com"
```

And then to add the ORM behavior to a class, you just have to include `Her::Model` in it:

```ruby
class User
  include Her::Model
end
```

After that, using Her is very similar to many ActiveModel-like ORMs:

```ruby
User.all      # => Fetches "https://api.example.com/users" and return an array of User objects
User.find(1)  # => Fetches "https://api.example.com/users/1" and return a User object
```

## Relationships

```ruby
class User
  include Her::Model
  has_many :comments
end

class Comment
  include Her::Model
end

user = User.find(1)
user.comments # => [#<Comment id=1>, #<Comment id=2>]
```

## Custom requests

You can easily add custom methods for your models. You can either use `get_collection` (which maps the returned data to a collection of resources), `get_resource` (which maps the returned data to a single resource) or `get_raw` (which yields the parsed data return from the HTTP request).

```ruby
class User
  include Her::Model

  def self.popular
    get_collection("/users/popular")
  end

  def self.total
    get_raw("/users/stats") do |parsed_data|
      parsed_data[:data][:total_users]
    end
  end
end

User.popular  # => [#<User id=1>, #<User id=2>]
User.total    # => 42
```
