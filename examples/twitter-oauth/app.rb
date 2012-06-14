# Create custom parser
class TwitterParser < Faraday::Response::Middleware
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

# See https://dev.twitter.com/apps
TWITTER_CREDENTIALS = {
  :consumer_key => "",
  :consumer_secret => "",
  :token => "",
  :token_secret => ""
}

# Initialize API
Her::API.setup :url => "https://api.twitter.com/1/" do |builder|
  builder.use FaradayMiddleware::OAuth, TWITTER_CREDENTIALS
  builder.use Faraday::Request::UrlEncoded
  builder.use TwitterParser
  builder.use Faraday::Adapter::NetHttp
end

# Define classes
class Tweet
  include Her::Model

  def self.timeline
    get "/statuses/home_timeline.json"
  end

  def self.mentions
    get "/statuses/mentions.json"
  end

  def username
    user[:screen_name]
  end
end

get "/" do
  @tweets = Tweet.mentions
  haml :index
end
