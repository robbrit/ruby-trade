require_relative 'server'

DEFAULT_WEBSERVER_PORT = 8080
DEFAULT_FEED_PORT = 9000
DEFAULT_ORDER_PORT = 9001

class App
  def initialize
    @server = Server.new
  end

  def start
    @server.start order_port: DEFAULT_ORDER_PORT,
      feed_port: DEFAULT_FEED_PORT,
      webserver_port: DEFAULT_WEBSERVER_PORT
  end
end

app = App.new
app.start
