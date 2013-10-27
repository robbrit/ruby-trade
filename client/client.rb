require 'socket'
require 'json'
require 'em-zeromq'

require_relative "order"

DEFAULT_FEED_PORT = 9000
DEFAULT_ORDER_PORT = 9001
DEFAULT_HEARTBEAT = 5
MAX_HEARTBEAT_FAILS = 5
HEARTBEAT_FAILTIME = 10

module RubyTrade
  module ConnectionClient
    def self.setup username, parent
      @@username, @@parent = username, parent
    end

    def post_init
      # identify with the server
      data = {
        action: "identify",
        name: @@username
      }.to_json

      send_data_f data

      puts "connected."

      @order_no = 0
      @orders = {}

      @@parent.child = self
      @@parent.on_connect
    end

    def send_order side, size, price
      @order_no += 1

      @orders[@order_no] = Order.new @order_no, side, price, size

      send_data_f({
        action: "new_order",
        local_id: @order_no,
        size: size,
        price: price,
        side: side
      }.to_json)
    end

    def buy amount, args
      send_order "buy", amount, args[:at]
    end

    def sell amount, args
      send_order "sell", amount, args[:at]
    end

    def send_data_f data
      send_data "\x02#{data}\x03"
    end

    def clean data
      if data.length > 2
        data.split("\x03\x02")[1..-2]
      else
        []
      end
    end

    def receive_data data
      clean(data).each do |msg|
        handle_message JSON.parse msg
      end
    end

    def handle_message data
      case data["action"]
      when "order_accept"
      when "order_fill"
        @@parent.on_fill @orders[data["local_id"]], data["amount"]
      when "order_partial_fill"
        @@parent.on_partial_fill @orders[data["local_id"]], data["amount"]
      when "order_cancel"
      end
    end
  end

  module Client
    def self.on_connect *args; puts "blah"; end
    def self.on_tick *args; end
    def self.on_fill *args; end
    def self.on_partial_fill *args; end

    module ClassMethods
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

      def connect_to server, args
        feed_port = args[:feed_port] || DEFAULT_FEED_PORT
        order_port = args[:order_port] || DEFAULT_ORDER_PORT
        user = args[:as]

        if not user
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

          ConnectionClient.setup user, self

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
