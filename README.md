# Her

[![Build Status](https://secure.travis-ci.org/remiprev/her.png)](http://travis-ci.org/remiprev/her)

Her is an ORM (Object Relational Mapper) that maps REST resources to Ruby objects. It is designed to build applications that are powered by a RESTful API.

## Installation

In your Gemfile, add:

    gem "her"

## Usage

To add the ORM to a class, you just have to include `Her::Model` in it and define which API you want it to be bound to. For example, with Rails, you would define a `config/initializers/her.rb` file with this:

```ruby
$my_api = Her::API.new
$my_api.setup :base_uri => "https://api.example.com"
```

And then, for each of your models:

```ruby
class User
  include Her::Model
  uses_api $my_api
end
```

After that, using Her is very similar to many ActiveModel-like ORMs:

```ruby
User.all     # => Fetches "https://api.example.com/users" and return an array of User objects
User.find(1) # => Fetches "https://api.example.com/users/1" and return a User object
```
