# Testing Her models

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
      klass.uses_api (api = Her::API.new)

      # Here, you would customize this for your own API (URL, middleware, etc)
      # like you have done in your application’s initializer
      api.setup :url => "http://api.example.com" do |connection|
        connection.use Her::Middleware::FirstLevelParseJSON
        connection.use Faraday::Request::UrlEncoded
        connection.adapter(:test) { |s| yield(s) }
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
      stub.get("/users/popular") { |env| [200, {}, [{ :id => 1, :name => "Tobias Fünke" }, { :id => 2, :name => "Lindsay Fünke" }].to_json] }
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
        stub.get("/posts/recent") { |env| [200, {}, [{ :id => 1 }, { :id => 2 }].to_json] }
      end
    end

    subject { Post.recent }
    its(:length) { should == 2 }
    its(:errors) { should be_empty }
  end

  describe :archived do
    before do
      stub_api_for(Post) do |stub|
        stub.get("/posts/archived") { |env| [200, {}, [{ :id => 1 }, { :id => 2 }].to_json] }
      end
    end

    subject { Post.archived }
    its(:length) { should == 2 }
    its(:errors) { should be_empty }
  end
end
```
