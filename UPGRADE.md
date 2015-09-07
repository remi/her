# Upgrade Her

Here is a list of notable changes by release. Her follows the [Semantic Versioning](http://semver.org/) system.

## 0.8.1 (Note: 0.8.0 yanked)

- Initial support for JSONAPI [link](https://github.com/remiprev/her/pull/347)
- Fix for has_one association parsing [link](https://github.com/remiprev/her/pull/352)
- Fix for escaping path variables HT @marshall-lee [link](https://github.com/remiprev/her/pull/354)
- Fix syntax highlighting in README HT @tippenein [link](https://github.com/remiprev/her/pull/356)
- Fix associations with Active Model Serializers HT @minktom [link](https://github.com/remiprev/her/pull/359)

## 0.7.6

- Loosen restrictions on ActiveSupport and ActiveModel to accommodate security fixes [link](https://github.com/remiprev/her/commit/8ff641fcdaf14be7cc9b1a6ee6654f27f7dfa34c)

## 0.7.5

- Performance fix for responses with large number of objects [link](https://github.com/remiprev/her/pull/337)
- Bugfix for dirty attributes [link](https://github.com/remiprev/her/commit/70285debc6837a33a3a750c7c4a7251439464b42)
- Add ruby 2.1 and 2.2 to travis test run. We will likely be removing official 1.9.x support in the near future, and 
will begin to align our support with the official ruby maintenance schedule. 
- README updates

## 0.6

Associations have been refactored so that calling the association name method doesn’t immediately load or fetch the data.

```ruby
class User
  include Her::Model
  has_many :comments
end

# This doesn’t fetch the data yet and it’s still chainable
comments = User.find(1).comments

# This actually fetches the data
puts comments.inspect

# This is no longer possible in her-0.6
comments = User.find(1).comments(:approved => 1)

# To pass additional parameters to the HTTP request, we now have to do this
comments = User.find(1).comments.where(:approved => 1)
```

## 0.5

Her is now compatible with `ActiveModel` and includes `ActiveModel::Validations`.

Before 0.5, the `errors` method on an object would return an error list received from the server (the `:errors` key defined by the parsing middleware). But now, `errors` returns the error list generated after calling the `valid?` method (or any other similar validation method from `ActiveModel::Validations`). The error list returned from the server is now accessible from the `response_errors` method.

Since 0.5.5, Her provides a `store_response_errors` method, which allows you to choose the method which will return the response errors. You can use it to revert Her back to its original behavior (ie. `errors` returning the response errors):

```ruby
class User
  include Her::Model
  store_response_errors :errors
end

user = User.create(:email => "foo") # POST /users returns { :errors => ["Email is invalid"] }
user.errors # => ["Email is invalid"]
```

## 0.2.4

Her no longer includes default middleware when making HTTP requests. The user has now to define all the needed middleware. Before:

```ruby
Her::API.setup :url => "https://api.example.com" do |connection|
  connection.insert(0, FaradayMiddle::OAuth)
end
```

Now:

```ruby
Her::API.setup :url => "https://api.example.com" do |connection|
  connection.use FaradayMiddle::OAuth
  connection.use Her::Middleware::FirstLevelParseJSON
  connection.use Faraday::Request::UrlEncoded
  connection.use Faraday::Adapter::NetHttp
end
```

## 0.2

The default parser middleware has been replaced to treat first-level JSON data as the resource or collection data. Before it expected this:

```json
{ "data": { "id": 1, "name": "Foo" }, "errors": [] }
```

Now it expects this (the `errors` key is not treated as resource data):
  
```json
{ "id": 1, "name": "Foo", "errors": [] }
```

If you still want to get the old behavior, you can use `Her::Middleware::SecondLevelParseJSON` instead of `Her::Middleware::FirstLevelParseJSON` in your middleware stack.
