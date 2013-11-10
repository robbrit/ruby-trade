require "sinatra/base"
require "sinatra-websocket"
require "thin"
require "rack"
require 'observer'
require 'json'

class Level1
  include Observable

  attr_reader :level1, :accounts

  def initialize
    @level1 = {
      bid: 0.0,
      ask: 0.0,
      last: 0.0
    }
  end

  def update_level1 level1
    @level1 = level1
    changed
    notify_observers :level1, level1
  end

  def update_accounts accounts
    @accounts = accounts
    changed
    notify_observers :accounts, accounts
  end
end

class SocketWrapper
  def initialize socket, level1
    level1.add_observer self
    @level1 = level1
    @socket = socket
  end

  def close
    @level1.delete_observer self
  end

  def update action, *data
    case action
    when :level1
      @socket.send({
        action: action,
        level1: data[0]
      }.to_json)
    when :accounts
      @socket.send({
        action: action,
        accounts: data[0]
      }.to_json)
    end
  end
end

class Webapp < Sinatra::Base
  configure do
    set :threaded, false
  end

  set :public_folder, "public"
  set :sockets, []

  get "/" do
    redirect "/index.html"
  end

  get "/ws" do
    request.websocket do |ws|
      wrapper = nil

      ws.onopen do
        wrapper = SocketWrapper.new ws, @@level1
        wrapper.update :level1, @@level1.level1
        settings.sockets << wrapper
      end

      ws.onclose do
        wrapper.close
        settings.sockets.delete wrapper
      end

      ws.onmessage do |msg|
        # don't need to do anything
      end
    end
  end

  def self.setup
    @@level1 = Level1.new
  end

  def self.level1_update level1
    @@level1.update_level1 level1
  end

  def self.update_accounts accounts
    @@level1.update_accounts accounts
  end
end

def run_webserver opts
  Webapp.setup

  webapp = Webapp.new

  dispatch = Rack::Builder.app do
    map "/" do
      run webapp
    end
  end

  Rack::Server.start({
    app: dispatch,
    server: "thin",
    host: "0.0.0.0",
    port: opts[:port]
  })
end
