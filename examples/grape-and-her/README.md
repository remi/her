# Grape + Her example

This is an example of how to use Her to consume a simple REST API.

## Usage

```shell
# Go to the example directory
$ cd examples/grape-and-her

# Go to each application and run `bundle install`
$ cd api; bundle install; cd ..
$ cd consumer; bundle install; cd ..

# Start foreman with the Procfile
$ foreman start
```

This should start the API on `http://0.0.0.0:3100` and the consumer on `http://0.0.0.0:3200`
