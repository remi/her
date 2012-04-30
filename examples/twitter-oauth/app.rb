# Create custom parser
class TwitterSearchParser < Faraday::Response::Middleware
  METADATA_KEYS = [:completed_in, :max_id, :max_id_str, :next_page, :page, :query, :refresh_url, :results_per_page, :since_id, :since_id_str]

  def on_complete(env)
    json = MultiJson.load(env[:body], :symbolize_keys => true)
    errors = [json.delete(:error)]
    env[:body] = {
      :data => json,
      :errors => errors,
      :metadata => {},
    }
  end
end

TWITTER_CREDENTIALS = {
  :consumer_key => "",
  :consumer_secret => "",
  :token => "",
  :token_secret => ""
}

# Initialize API
Her::API.setup :base_uri => "https://api.twitter.com/1/", :parse_middleware => TwitterSearchParser, :add_middleware => [FaradayMiddleware::OAuth]

# Define classes
class Tweet
  include Her::Model

  def self.timeline
    get "/statuses/home_timeline.json"
  end

  def username
    user[:screen_name]
  end
end

get "/" do
  @tweets = Tweet.timeline
  haml :index
end
