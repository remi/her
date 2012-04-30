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

# Initialize API
Her::API.setup :base_uri => "http://search.twitter.com", :parse_middleware => TwitterSearchParser

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
