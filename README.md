# Her [![Build Status](https://secure.travis-ci.org/remiprev/her.png?branch=master)](http://travis-ci.org/remiprev/her) [![Gem dependency status](https://gemnasium.com/remiprev/her.png?travis)](https://gemnasium.com/remiprev/her)

Her is an ORM (Object Relational Mapper) that maps REST resources to Ruby objects. It is designed to build applications that are powered by a RESTful API instead of a database.

## Installation

In your Gemfile, add:

```ruby
gem "her"
```

That’s it!

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

After that, using Her is very similar to many ActiveRecord-like ORMs:

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

You can look into the `examples` directory for sample applications using Her. For a complete reference of all the methods you can use, check out [the documentation](http://rdoc.info/github/remiprev/her).

## History

Most of Her’s core codebase was written on a Saturday morning ([first commit](https://github.com/remiprev/her/commit/689d8e88916dc2ad258e69a2a91a283f061cbef2) at 7am!) while I was visiting my girlfiend’s family in [Ayer’s Cliff](https://en.wikipedia.org/wiki/Ayer%27s_Cliff).

I told myself a few weeks before that it would be great to build a gem to replace Rails’ [ActiveResource](http://api.rubyonrails.org/classes/ActiveResource/Base.html) since it was barely maintained, lacking features and hard to extend/customize. I had built a few of these REST-powered ORMs for client projects before but I decided I wanted to write one for myself that I could release as an open-source project.

## Middleware

See [MIDDLEWARE.md](https://github.com/remiprev/her/blob/master/MIDDLEWARE.md) to learn how to use [Faraday](https://github.com/technoweenie/faraday)’s middleware to customize how Her handles HTTP requests and responses.

## Features

See [FEATURES.md](https://github.com/remiprev/her/blob/master/FEATURES.md) to learn about Her’s advanced features.

## Testing

See [TESTING.md](https://github.com/remiprev/her/blob/master/TESTING.md) to learn how to test models using stubbed HTTP requests.

## Upgrade

See the [UPGRADE.md](https://github.com/remiprev/her/blob/master/UPGRADE.md) for backward compability issues.

## Her IRL

Most projects I know that use Her are internal or private projects but here’s a list of public ones:

* [tumbz](https://github.com/remiprev/tumbz)

## Contribute

Yes please! Feel free to contribute and submit issues/pull requests [on GitHub](https://github.com/remiprev/her/issues).

See [CONTRIBUTING.md](https://github.com/remiprev/her/blob/master/CONTRIBUTING.md) for best practices.

### Contributors

These fine folks helped with Her:

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

## License

Her is © 2012 [Rémi Prévost](http://exomel.com) and may be freely distributed under the [MIT license](https://github.com/remiprev/her/blob/master/LICENSE). See the `LICENSE` file.
