# Create custom parser
class TwitterSearchParser < Faraday::Response::Middleware
  METADATA_KEYS = [:completed_in, :max_id, :max_id_str, :next_page, :page, :query, :refresh_url, :results_per_page, :since_id, :since_id_str]

  def on_complete(env)
    json = MultiJson.load(env[:body], :symbolize_keys => true)
    env[:body] = {
      :data => json[:results],
      :errors => [json[:error]],
      :metadata => json.select { |key, value| METADATA_KEYS.include?(key) }
    }
  end
end

class MyCache
  def initialize
    @cache = {}
  end

  def write(key, value)
    @cache[key] = value
  end

  def read(key)
    @cache[key]
  end

  def fetch(key, &block)
    return value = read(key) if value.nil?
    write key, yield
  end
end

$cache = MyCache.new

# Initialize API
Her::API.setup :base_uri => "http://search.twitter.com" do |builder|
  builder.swap Her::Middleware::FirstLevelParseJSON, TwitterSearchParser
  builder.use FaradayMiddleware::Caching, $cache
end

# Define classes
class Tweet
  include Her::Model

  def self.search(query, attrs={})
    get("/search.json", attrs.merge(:q => query))
  end
end

get "/" do
  @tweets = Tweet.search("github", :rpp => 30)
  haml :index
end
