# Her

[![Build Status](https://secure.travis-ci.org/remiprev/her.png)](http://travis-ci.org/remiprev/her)

Her is an ORM (Object Relational Mapper) that maps REST resources to Ruby objects. It is designed to build applications that are powered by a RESTful API and no database.

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
User.all
# GET "https://api.example.com/users" and return an array of User objects

User.find(1)
# GET "https://api.example.com/users/1" and return a User object

@user = User.create(:fullname => "Tobias Fünke")
# POST "https://api.example.com/users" with the data and return a User object

@user = User.new(:fullname => "Tobias Fünke")
@user.occupation = "actor"
@user.save
# POST "https://api.example.com/users" with the data and return a User object

@user = User.find(1)
@user.fullname = "Lindsay Fünke"
@user.save
# PUT "https://api.example.com/users/1" with the data and return+update the User object
```

## Relationships

You can define `has_many` relationships in your models. The relationship data is handled in two different ways. When parsing a resource from JSON data, if there’s a relationship data included, it will be used to create new Ruby objects.

If no relationship data was included when parsing a resource, calling a method with the same name as the relationship will fetch the data (providing there’s an HTTP request available for it).

For example, with this setup:

```ruby
class User
  include Her::Model
  has_many :comments
end

class Comment
  include Her::Model
end
```

If there’s relationship data in the resource, no extra HTTP request is made when calling the `#comments` method and an array of resources are returned:

```ruby
@user = User.find(1) # { :data => { :id => 1, :name => "George Michael Bluth", :comments => [{ :id => 1, :text => "Foo" }, { :id => 2, :text => "Bar" }] }}
@user.comments # => [#<Comment id=1>, #<Comment id=2>] fetched directly from @user
```

If there’s no relationship data in the resource, an extra HTTP request (to `GET /users/1/comments`) is made when calling the `#comments` method:

```ruby
@user = User.find(1) # { :data => { :id => 1, :name => "George Michael Bluth" }}
@user.comments # => [#<Comment id=1>, #<Comment id=2>] fetched from /users/1/comments
```

However, subsequent calls to `#comments` will not trigger the extra HTTP request.

## Custom requests

You can easily add custom methods for your models. You can either use `get_collection` (which maps the returned data to a collection of resources), `get_resource` (which maps the returned data to a single resource) or `get_raw` (which yields the parsed data return from the HTTP request). Other HTTP methods are supported (`post_raw`, `put_resource`, etc.)

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

## Things to be done

* Deleting resources
* Support for Faraday middleware
* Hooks before save, update, create, destroy, etc.
* Better error handling
* Better introspection for debug
* Better documentation

## Contributors

Feel free to contribute and submit issues/pull requests [on GitHub](https://github.com/remiprev/her/issues).

Take a look at the `spec` folder before you do, and make sure `bundle exec rake spec` passes after your modifications :)

## License

Her is © 2012 [Rémi Prévost](http://exomel.com) and may be freely distributed under the [LITL license](https://github.com/remiprev/her/blob/master/LICENSE). See the `LICENSE` file.
