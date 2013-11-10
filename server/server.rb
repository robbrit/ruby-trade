require 'em-zeromq'
require 'json'

require_relative 'exchange'
require_relative 'web_server'
require_relative 'common'

AccountUpdateFrequency = 5

class OrderServer < EM::Connection
  include LineCleaner

  def self.setup parent
    @@exchange = Exchange.new
    @@parent = parent

    EM.add_periodic_timer DividendFrequency do
      @@exchange.pay_dividends
    end

    EM.add_periodic_timer AccountUpdateFrequency do
      level1 = @@exchange.level1
      Webapp.update_accounts(@@exchange.accounts.select { |account|
        #not account.ai?
        true
      }.map { |account|
        [account.name, account.net_value(level1[:last]), account.stock, account.cash]
      }.sort_by { |row|
        -row[1]
      })
    end
  end

  def post_init
    @buffer = ""
    @my_orders = {}
  end

  def unbind
    # cancel the orders for this client
    puts "Connection closed from #{@account.name}, killing orders"
    @my_orders.values.each do |order|
      @@exchange.cancel_order order
    end
    @@parent.tick @@exchange
  end

  def update action, *args
    case action
    when :fill
      order, price, amount = args
      @my_orders.delete order.id
      @account.on_trade order, price, amount
      send_data_f({
        action: "order_fill",
        amount: amount,
        price: price,
        local_id: order.local_id
      }.to_json)
      @@parent.tick @@exchange
    when :partial_fill
      order, price, amount = args
      @account.on_trade order, price, amount
      send_data_f({
        action: "order_partial_fill",
        amount: amount,
        price: price,
        local_id: order.local_id
      }.to_json)
      @@parent.tick @@exchange
    when :cancel
      order = args[0]
      @my_orders.delete order.id
      send_data_f({
        action: "order_cancel",
        local_id: order.local_id
      }.to_json)
      @@parent.tick @@exchange
    when :dividend
      send_data_f({
        action: "dividend",
        value: args[0][:value]
      }.to_json)
    end
  end

  def send_data_f data
    send_data "\x02#{data}\x03"
  end

  def handle_message data
    case data["action"]
    when "identify"
      _, ip = Socket.unpack_sockaddr_in get_peername
      data["peer_name"] = ip
      puts "User #{data['name']}@#{data["peer_name"]} connected."

      @account.delete_observer self if @account
      @account = @@exchange.identify data
      @account.add_observer self

      send_data_f({
        action: "account_update",
        cash: @account.cash,
        stock: @account.stock
      }.to_json)
    when "new_order"
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
          id: order.id,
          price: order.price
        }.to_json)

        @my_orders[order.local_id] = order
        @@exchange.send_order order
        @@parent.tick @@exchange
      end
    when "cancel_order"
      order = @my_orders[data["id"]]
      if order
        @@exchange.cancel_order order
        @@parent.tick @@exchange
      else
        puts "No order with ID #{data["id"]}"
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
    msg = {
      action: "tick",
      level1: exchange.level1
    }
    Webapp.level1_update exchange.level1

    @feed_socket.send_msg(msg.to_json)
  end

  def start args = {}
    order_port = args[:order_port]
    feed_port = args[:feed_port]
    webserver_port = args[:webserver_port]

    @context = EM::ZeroMQ::Context.new 1

    EM.run do
      OrderServer.setup self

      puts "Listening for clients on #{order_port}"
      EM.start_server "0.0.0.0", order_port, OrderServer

      puts "Hosting feed on #{feed_port}"
      @feed_socket = @context.socket ZMQ::PUB
      @feed_socket.bind "tcp://*:#{feed_port}"

      puts "Loading webserver on #{webserver_port}"
      run_webserver port: webserver_port

      Signal.trap("INT") { EM.stop }
      Signal.trap("TERM") { EM.stop }
    end
  end
end
