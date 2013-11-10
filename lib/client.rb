require 'socket'
require 'json'
require 'em-zeromq'

require_relative "order"
require_relative "../server/common"

DEFAULT_FEED_PORT = 9000
DEFAULT_ORDER_PORT = 9001

module RubyTrade
  module ConnectionClient
    include LineCleaner

    def self.setup args, parent
      @@username = args[:as]
      @@ai = args[:ai] || false
      @@parent = parent
    end

    def post_init
      # identify with the server
      data = {
        action: "identify",
        name: @@username,
        ai: @@ai
      }.to_json

      send_data_f data

      @buffer = ""
      @order_no = 0
      @orders = {}
      @cash, @stock = 0, 0
      @connect_triggered = false

      @@parent.child = self
    end

    def cash; @cash; end
    def stock; @stock; end

    def send_order side, size, price
      @order_no += 1

      order = Order.new @order_no, side, price, size
      order.add_observer self

      @orders[@order_no] = order

      send_data_f({
        action: "new_order",
        local_id: @order_no,
        size: size,
        price: price,
        side: side
      }.to_json)

      order
    end

    def update what, *args
      case what
      when :cancel
        order = args[0]
        send_data_f({
          action: "cancel_order",
          id: order.id
        }.to_json)
      else
        # Don't need to handle anything else
      end
    end

    # Send a buy order
    def buy amount, args
      send_order "buy", amount, args[:at]
    end

    # Send a sell order
    def sell amount, args
      send_order "sell", amount, args[:at]
    end

    # Send data with tokens
    def send_data_f data
      send_data "\x02#{data}\x03"
    end

    # Called by EM when we receive data
    def receive_data data
      clean(data).each do |msg|
        handle_message JSON.parse msg
      end
    end

    # Recalculate cash/stock balances
    def update_account data
      order = @orders[data["local_id"]]

      if order.side == "buy"
        @cash -= data["price"] * data["amount"]
        @stock += data["amount"]
      else
        @cash += data["price"] * data["amount"]
        @stock -= data["amount"]
      end
    end

    # Process a message from the server
    def handle_message data
      case data["action"]
      when "order_accept"
        @orders[data["local_id"]].price = data["price"]
      when "order_fill"
        update_account data
        @@parent.on_fill @orders[data["local_id"]], data["amount"], data["price"]
      when "order_partial_fill"
        update_account data
        @@parent.on_partial_fill @orders[data["local_id"]], data["amount"], data["price"]
      when "order_cancel"
        # Don't need to do anything here
      when "account_update"
        @cash, @stock = data["cash"], data["stock"]

        if not @connect_triggered
          @connect_triggered = true
          @@parent.on_connect
        end
      when "dividend"
        @cash += data["value"]
        @@parent.on_dividend data["value"]
      end
    end
  end

  module Client
    module ClassMethods
      def on_connect *args; end
      def on_tick *args; end
      def on_fill *args; end
      def on_partial_fill *args; end
      def on_dividend *args; end

      # hook so we can call child methods
      def child= child
        @@child = child
      end

      # Called when we receive feed data
      def process_message data
        case data["action"]
        when "tick"
          self.on_tick data["level1"]
        end
      end

      def buy *args; @@child.buy(*args); end
      def sell *args; @@child.sell(*args); end
      def cash; @@child.cash; end
      def stock; @@child.stock; end

      def connect_to server, args
        feed_port = args[:feed_port] || DEFAULT_FEED_PORT
        order_port = args[:order_port] || DEFAULT_ORDER_PORT

        if not args[:as]
          raise "Need to specify a username: connect_to \"...\", as: \"username\""
        end

        @zmq_context = EM::ZeroMQ::Context.new 1

        EM.run do
          @feed = @zmq_context.socket ZMQ::SUB

          puts "Listening to feed on #{server}:#{feed_port}"
          @feed.connect "tcp://#{server}:#{feed_port}"
          @feed.subscribe

          @feed.on :message do |part|
            begin
              self.process_message JSON.parse part.copy_out_string
            ensure
              part.close
            end
          end

          ConnectionClient.setup args, self

          puts "Connecting to order server #{server}:#{order_port}"
          EM.connect server, order_port, ConnectionClient

          Signal.trap("INT") { EM.stop }
          Signal.trap("TERM") { EM.stop }
        end
      end
    end

    def self.included subclass
      subclass.extend ClassMethods
    end
  end
end
