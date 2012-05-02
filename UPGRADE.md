Here is a list of backward-incompatible changes that were introduced while Her is still \<1.0. After reaching 1.0, it will follow the [Semantic Versioning](http://semver.org/) system.

## 0.2.4

* Her no longer includes default middleware when making HTTP requests. The user has now to define all the needed middleware. Before:

      Her::API.setup :base_uri => "https://api.example.com" do |builder|
        builder.insert(0, FaradayMiddle::OAuth)
      end

  Now:
    
      Her::API.setup :base_uri => "https://api.example.com" do |builder|
        builder.use FaradayMiddle::OAuth
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.use Faraday::Adapter::NetHttp
      end

## 0.2

* The default parser middleware has been replaced to treat first-level JSON data as the resource or collection data. Before it expected this:

      { "data": { "id": 1, "name": "Foo" }, "errors": [] }
        
   Now it expects this (the `errors` key is not treated as resource data):
   
      { "id": 1, "name": "Foo", "errors": [] }
      
   If you still want to get the old behavior, you can use `Her::Middleware::SecondLevelParseJSON` instead of `Her::Middleware::FirstLevelParseJSON` in your middleware stack.