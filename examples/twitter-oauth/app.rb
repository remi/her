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
Her::API.setup :url => "https://api.twitter.com/1/" do |connection|
  connection.use FaradayMiddleware::OAuth, TWITTER_CREDENTIALS
  connection.use Faraday::Request::UrlEncoded
  connection.use TwitterParser
  connection.use Faraday::Adapter::NetHttp
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

############################################

# config/initializers/her.rb
Her::API.setup :url => "https://api.example.com" do |connection|
  connection.use MyAuthentication
  connection.use Faraday::Request::UrlEncoded
  connection.use Her::Middleware::DefaultParseJSON
  connection.use Faraday::Adapter::NetHttp
end

# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_filter do
    MyApp.current_user = session[:user_id] ? User.find(session[:user_id]) : nil
  end
end

# lib/my_app.rb
class MyApp
  def self.current_user=(user)
    @current_user = user
  end

  def self.current_user
    @current_user
  end
end

# lib/my_authentication.rb
class MyAuthentication < Faraday::Middleware
  def call(env)
    env[:request_headers]["X-API-Token"] = MyApp.current_user.token if MyApp.current_user?
    @app.call(env)
  end
end
