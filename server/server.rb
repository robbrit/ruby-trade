require 'em-zeromq'
require 'json'

require_relative 'exchange'

class OrderServer < EM::Connection
  def self.setup parent
    @@exchange = Exchange.new
    @@parent = parent
  end

  def update action, *args
    case action
    when :fill
      order, amount = args
      send_data_f({
        action: "order_fill",
        amount: amount,
        price: order.price,
        local_id: order.local_id
      }.to_json)
      @@parent.tick @@exchange
    when :partial_fill
      order, amount = args
      send_data_f({
        action: "order_partial_fill",
        amount: amount,
        price: order.price,
        local_id: order.local_id
      }.to_json)
      @@parent.tick @@exchange
    when :cancel
      order = args[0]
      send_data_f({
        action: "order_cancel",
        local_id: order.local_id
      }.to_json)
      @@parent.tick @@exchange
    end
  end

  def send_data_f data
    send_data "\x02#{data}\x03"
  end
  
  def clean data
    if data.length > 2
      data[1..-2].split("\x03\x02")
    else
      []
    end
  end

  def handle_message data
    case data["action"]
    when "identify"
      _, ip = Socket.unpack_sockaddr_in get_peername
      data["peer_name"] = ip
      puts "User #{data['name']}@#{data["peer_name"]} connected."
      @account = @@exchange.identify data
    when "new_order"
      puts "new order"

      error, order = @@exchange.new_order @account, data

      if error
        # reject the message
        send_data_f({
          action: "order_reject",
          local_id: data["local_id"],
          reason: error
        }.to_json)
      else
        order.add_observer self

        # it's good, accept it
        send_data_f({
          action: "order_accept",
          local_id: data["local_id"],
          id: order.id
        }.to_json)

        @@exchange.send_order order
        @@parent.tick @@exchange
      end
    end
  end

  def receive_data data
    clean(data).each do |msg|
      handle_message JSON.parse msg
    end
  end
end

class Server
  def tick exchange
    puts "sending tick"
    msg = {
      action: "tick",
      level1: exchange.level1
    }
    puts msg.inspect
    puts @feed_socket.send_msg(msg.to_json)
  end

  def start args = {}
    order_port = args[:order_port]
    feed_port = args[:feed_port]

    @context = EM::ZeroMQ::Context.new 1

    OrderServer.setup self

    EM.run do
      puts "Listening for clients on #{order_port}"
      EM.start_server "0.0.0.0", order_port, OrderServer

      puts "Hosting feed on #{feed_port}"
      @feed_socket = @context.socket ZMQ::PUB
      @feed_socket.bind "tcp://*:#{feed_port}"

      Signal.trap("INT") { EM.stop }
      Signal.trap("TERM") { EM.stop }
    end
  end
end
