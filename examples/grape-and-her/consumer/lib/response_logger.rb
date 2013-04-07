require 'stringio'
require 'logger'

class ResponseBodyLogger < Faraday::Response::Middleware
  def initialize(app, logger)
    @app = app
    @logger = logger
  end

  def on_complete(env)
    @logger.info ""
    @logger.info env[:body]
    @logger.info "\n"
  end
end

$strio = StringIO.new
$logger = Logger.new($strio).tap { |logger| logger.formatter = proc { |severity, datetime, progname, msg| "#{msg}\n" } }
