begin
  require 'connection_pool'
rescue LoadError
  fail "'connection_pool' gem is required to use Her::API's pool_size and pool_timeout options"
end
require 'her/model/http'

module Her
  class API
    class ConnectionPool < ::ConnectionPool
      DELEGATED_METHODS = Model::HTTP::METHODS

      DELEGATED_METHODS.each do |method|
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{method}(*args, &blk)
            with do |conn|
              conn.#{method}(*args, &blk)
            end
          end
        RUBY
      end
    end
  end
end
