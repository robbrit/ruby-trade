# Ruby-Trade

Ruby-Trade is a game where each player builds an AI to compete against other AIs 
in a virtual stock exchange.

The way it works is just like a real stock exchange: you place orders to trade
into the market to buy or sell shares.

## Installation

Just install the gem (not working just yet)

    gem install ruby-trade

## Lingo

Before getting started, there are a few definitions that you should know about:

* "fill" - An event triggered when one of your orders gets fully executed (that
  is, all the shares that you requested to buy or sell are bought/sold).
* "partial fill" - The same as a fill, but not all of the shares in your order
  were executed. For example if you sent an order to buy 100 shares and someone
  only sold you 50, it is called a partial fill.
* "bid" - The highest price of all the buy orders.
* "ask" - The lowest price of all the sell orders.
* "last" - The last price that some shares were traded at.
* "spread" - The difference between the bid and the ask.
* "position" - The amount of stock that you have. If it is positive then it is
  called a "long" position, if it is negative then it is called a "short" position.
  Yes, it is possible to have negative shares.
* "Level 1" - The bid, the ask, and the last.
* "Outside the market" - Any buy order with a price less than the bid or any sell
  order with a price higher than the ask is considered "outside the market."

## Client

Here is an example client:

    require 'ruby-trade'

    class MyApp
      include RubyTrade::Client

      # Called by the system when we connect to the exchange server
      def self.on_connect
        puts "sending order"
        @buy_order = buy 100, at: 10.0
      end

      # Called whenever something happens on the exchange
      def self.on_tick level1
        puts "Cash: #{cash}"
        puts "Stock: #{stock}"
        puts "Bid: #{level1["bid"]}"
        puts "Ask: #{level1["ask"]}"
        puts "Last: #{level1["last"]}"
      end

      # Called when an order gets filled
      def self.on_fill order, amount, price
        puts "Order ID #{order.id} was filled for #{amount} shares at $%.2f" % price
      end

      # Called when an order gets partially filled
      def self.on_partial_fill order, amount, price
        puts "Order ID #{order.id} was partially filled for #{amount} shares at $%.2f" % price

        # Cancel the order
        @buy_order.cancel!
      end

    end

    # Connect to the server
    MyApp.connect_to "127.0.0.1", as: "Jim"

## Events

### Dividend

Every half hour, a dividend is paid out. Anybody who has a long position will
gain cash equal to the dividend times the number of shares that they own; anybody
with a short position will lose cash equal to the dividend times the number of
shares that they are short.

### Big Trades

At random times during the trading session, a large trade may be made. These trades
will be set at some price outside the market, the distance determined randomly.
These trades do not count towards the score.

### Market Makers

While not really an event, there will be a number of traders in the market who
are designated as "market makers." They keep buy orders and sell orders a little
bit outside the market to ensure that there is usually someone there to buy when
people want to sell, or sell when people want to buy. Note that they are not
always there, so traders should not rely on them being there. They are not there
to make money and do not count towards the score.
