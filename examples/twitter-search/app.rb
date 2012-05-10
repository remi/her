# Create custom parser
class TwitterSearchParser < Faraday::Response::Middleware
  METADATA_KEYS = [:completed_in, :max_id, :max_id_str, :next_page, :page, :query, :refresh_url, :results_per_page, :since_id, :since_id_str]

  def on_complete(env)
    json = MultiJson.load(env[:body], :symbolize_keys => true)
    data = json.delete(:results)
    errors = [json.delete(:error)].compact
    env[:body] = {
      :data => data,
      :errors => errors,
      :metadata => json
    }
  end
end

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

$cache = MyCache.new

# Initialize API
Her::API.setup :url => "http://search.twitter.com" do |builder|
  builder.use Faraday::Request::UrlEncoded
  builder.use FaradayMiddleware::Caching, $cache
  builder.use TwitterSearchParser
  builder.use Faraday::Adapter::NetHttp
end

# Define classes
class Tweet
  include Her::Model

  def self.search(query, attrs={})
    get("/search.json", attrs.merge(:q => query))
  end
end

get "/" do
  @tweets = Tweet.search("justin bieber", :rpp => 30)
  haml :index
end
