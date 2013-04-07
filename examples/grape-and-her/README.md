# Grape + Her example

This is an example of how to use Her to consume a simple API. It consists of two separate applications, a REST API (powered by `grape` and `activerecord`) and a consumer application (powered by `sinatra` and `her`).

![](http://i.imgur.com/AGfYwzl.png)

## Installation and Usage

```shell
# Clone the repository
$ git clone git://github.com/remiprev/her.git

# Go to the example directory
$ cd her/examples/grape-and-her

# Go to each application and run `bundle install`
$ cd api; bundle install; cd ..
$ cd consumer; bundle install; cd ..

# Create the API database
$ cd api; sqlite3 db/development.db ""; bundle exec rake db:migrate; cd ..

# Start foreman with the Procfile
$ foreman start
```

This should start the API on `http://0.0.0.0:3100` and the consumer on `http://0.0.0.0:3200`
