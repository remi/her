api: ruby -C ./api -S bundle exec unicorn -p $API_PORT -c ./config/unicorn.rb -E $RACK_ENV
consumer: ruby -C ./consumer -S bundle exec unicorn -p $CONSUMER_PORT -c ./config/unicorn.rb -E $RACK_ENV
